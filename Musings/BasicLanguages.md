# Basic Languages on the Z80

These are some musings on the topic of how to implement Basic-like languages on the Z80, specifically the ZX Spectrum.  Sinclair Basic was comfortable enough to program in, but ran like a concrete rabbit.  BBC Basic, on the other hand, was much quicker.  My career took a decade long detour into programming language design and implementation, so I understand now why the Spectrum Basic implementation was so slow.  What I don't really understand was why Basic implementers didn't go straight to compilation or, at the very least, some half-decent P-code style scheme.  But they didn't.  I'd like to point out here that the Z80 is an interesting compilation target in that it is seemingly designed to thwart any attempt at efficient language implementation.  But my first computers were a ZX-81 and a ZX Spectrum and those things ran on Z80s and that's what I learned.  Here are my thoughts on the matter.

## The Z80

Ahhh, the Z80.  No two registers seem to do the same things.  It suffices to say this about the Z80:
* `SP` - 16-bit stack pointer, grows downwards, can push/pop any single 16-bit register pair;
* `HL` - 16-bit accumulator, general workhorse;
* `DE` - 16-bit register, plays slightly better with `HL` than other registers;
* `BC` - 16-bit register, fairly limited;
* `IX` and `IY` - 16-bit registers with fixed 8-bit offset indexed addressing modes, very slow;
* `A` - 8-bit accumulator;
* Indirect register loads and stores must go via `HL` and can only manage 8-bits at a time (e.g., to store `DE` one must do `ld (HL), E : inc HL : ld (HL), D : inc HL`, where `:` is the Z80 assembly language instruction separator);
* There is a "shadow" bank of registers for the main set, `HL`, `DE`, `BC`, but you have to swap the entire set;
* It's a little-endian architecture (i.e., least significant byte goes in the lower address).

I'll be comparing instruction sequences in terms of the number of "T-states" (i.e., clock ticks) it takes the Z80 to carry them out.

## A Digression Regarding Forth

Horrible language, never liked it, with the sole redeeming feature of being somewhat quicker than the Basic interpreters of the day.  I will return to this at some point.  That said, the Forth philosophy of reaching for simplicity is worth emulating.

## What Are We Talking About?

I'm going to posit a Basic-like language with the following kinds of structures:

* Variables and constants.  I'm going to simplify the discussion for the most part by assuming that all variables are global and all quantities are 16-bit numbers.  Obviously 16-bits is too small for general use (32-bits would be fine), but it grounds the discussion: if you can't do well at 16-bits, you can't do well at 32-bits!  The "everything is global" assumption matches the Basic programming style of the day.  I'll discuss other options at some point.

* Assignment: `x = e`, where `e` denotes an expression.

* Expressions with prefix operators, infix operators with precedence, built-in functions, and parentheses: `-x * (y + abs(z))`

* `if e1 ... elif e2 ... else ... end`

* `while e ... end` along with the usual `break` and `continue`

* Optionally `goto` and `gosub` and `:labels`, but these are neither here nor there.

* Built-in statements, such as `print e1, ...`

The syntax doesn't matter too much, although we'd obviously prefer to keep it Basic-like and LL(1) for ease of parsing (i.e., we require at most one token of look-ahead to decide what to do next).

User-defined functions can be added, but that's also something I intend to come back to in a bit.

## What Aren't We Talking About?

I'm not going to think about any real optimisations: no constant folding, no register allocation, no common sub-expression elimination.  The reason being that those things are relatively hard to very hard to accomplish, especially if you want a quick, reliable scheme amenable to the Basic REPL environment of the day.

## Virtual Machines

Regardless of whether we're implementing a pure interpreter (every line is parsed and evaluated every time it is visited), a tokenising interpreter (every line is pre-parsed on entry into some "simpler form" and these simpler forms are then interpreted), or a compiler (like a tokenising interpreter, but the "simpler forms" are executable machine code), we need to talk about the "virtual machine" which will evaluate these "simpler forms".

I'm going to claim that virtually all the implementation effort goes into parsing and processing expressions.  I'm going to assume expressing parsing is done via some shunting-yard algorithm to handle precedence etc. and convert the expression into the simpler form.  The nature of the simpler form is dictated by the VM and since our target is the lowly Z80, an obtusely non-orthogonal, register starved creature, our VM is going to be a stack machine.

This means that an expression such as `-x * (y + 1)` will be parsed into a simpler form like this:
```
VAR x
NEG
VAR y
LIT 1
ADD
MUL
```
where `VAR x` pushes the value in variable `x`, `LIT 1` pushes the literal constant 1, `NEG` replaces the top-of-stack with its negation, and `ADD` and `MUL` replace the top two stack items with their sum and product respectively.

An assignment `x = e` might have the simpler form
```
LVAR x
[[e]]
ASSIGN
```
where `LVAR x` pushes the address of variable `x`, `[[e]]` denotes the simpler form of expression `e`, and `ASSIGN` pops the value and variable address and writes the former to the latter.

I claim that the speed of our language will be dictated by how efficiently expressions are evaluated, since that is what programs will spend most of their time doing.

(To be clear: to the best of my knowledge, pretty much any of what I describe below would be substantially faster than any 1980s Basic interpreter.)

## Core VM Instructions

To ground the argument, I'm going to restrict discussion to the following VM "instructions":

* `NEXT` fetches and executes the next instruction;
* `VAR x` pushes the contents of variable `x`;
* `LIT k` pushes the literal value `k`;
* `OP1` stands for the application of any built-in arity 1 operator;
* `OP2` stands for the application of any built-in arity 2 operator.

Later on I intend to introduce `CALL` and `RET` instructions when exploring how user-defined functions might be supported.

## Keeping the Top-of-Stack (ToS) in a Register

A common optimisation in Forth implementations is to keep the topmost stack item in a register rather than in memory.  I'm going to assume that optimisation is in play for the purposes of this discussion.

## Interpreting Tokens or Token Threaded Code

TTC is a Forth-ism where each simple-form instruction must be examined to decide how it should be handled.  In this case, we might reasonably assume there are only a modest number of such which could be nicely handled with a jump table.  Let's assume the jump table all sits in the same 256-byte aligned "page" of memory, that tokens are just the low-byte of the corresponding jump-table addresses, and, reasonably, that we want to use a faster, non-indexed register pair as our "instruction pointer", which I'll abbreviate as IP.  This looks about the best one could do:
```
NEXT:
  ld A, (HL)    ; HL is our IP, but we could use BC or DE just as well.
  inc HL        ; Each token is a low byte of a jump table address.
  ld IXL, A     ; IXH always holds the jump table address high byte.
  jp (IX)       ; Jump into the jump table.
  
JUMP_TABLE:
  jp INSTR_1
  jp INSTR_2
  ...
  jp INSTR_N    ; Total overhead: 39 Ts.
```
The time taken to reach an instruction's code is 39 Ts (T-states).  If each instruction finishes by jumping to `NEXT` (3 bytes) rather than inlining it (6 bytes) the the total `NEXT` overhead of each instruction is 49 Ts.  For the sake of argument, we'll assume `NEXT` is inlined.  Now for the other key instructions.  
```
LIT:            ; The next two bytes in the instruction stream are the literal value.
  push DE       ; Push the current ToS (DE, in this case).
  ld E, (HL)
  inc HL
  ld D, (HL)
  inc HL        ; Read the literal instruction argument into ToS (DE).
  [NEXT]        ; Total: 37 Ts + 39 Ts [NEXT] = 76 Ts.

VAR:            ; The next two bytes in the instruction stream are the variable address.
  push DE       ; Push the current ToS.
  ld E, (HL)
  inc HL
  ld D, (HL)
  inc HL        ; Now DE holds the variable's address.
  ex DE, HL
  ld A, (HL)
  inc HL
  ld H, (HL)
  ld L, A
  ex DE, HL     ; Now DE (ToS) holds the variable's value.
  [NEXT]        ; Total overhead: 64 Ts + 39 Ts [NEXT] = 103 Ts.
  
OP1:            ; Arg is in ToS (DE).
  ...
  [NEXT]        ; Total overhead: 0 + 39 Ts [NEXT] = 39 Ts.
  
OP2:            ; Args are ToS (DE) and on stack.
  pop BC        ; Now BC and DE hold args.
  ...
  [NEXT]        ; Total overhead: 10 + 39 Ts [NEXT] = 49 Ts.
```
This approach pays a hefty performance cost to have single-byte instruction tokens.  Note that using `HL` as the IP gives us faster access to the instruction stream, but gets in the way of our `OP` implementations because `HL` is the favoured register for 16-bit operations on the Z80.

### Summary so far

| Implementation | `NEXT` | `LIT` | `VAR` | `OP1` | `OP2` |
|----------------|-------:|------:|------:|------:|------:|
| TTC            |     39 |    76 |   103 |    39 |    49 |

## Interpreting Pointers or Direct Threaded Code (Stack-as-IP Version)

DTC (another Forth-ism) replaces 8-bit tokens with the 16-bit addresses of the corresponding instruction implementations.  Now, stack operations on the Z80 are about two and a half times as fast as the equivalent register-based code (10 Ts vs 26 Ts), and a single `ret` op-code will pop an address off the stack and jump to it in only 10 Ts.  This suggests what I believe to be a novel idea: store the "simple form" instructions in reverse order and fetch them via the stack.  Of course, this means we have to use another (much slower) register pair for our data stack, but let's explore the idea and see what it produces.  In this scheme, `SP` is the instruction pointer, `HL` will be our data stack pointer, and `DE` will be ToS.
```
NEXT:
  ret           ; Total overhead: 10 Ts.  Inlined below.
  
LIT:
  ld (HL), D
  dec HL
  ld (HL), E
  dec HL        ; Previous ToS is now on the data stack.
  pop DE        ; Pop the literal value into DE (ToS).
  ret           ; Total overhead: 46 Ts.

VAR:
  ld (HL), D
  dec HL
  ld (HL), E
  dec HL        ; Previous ToS is now on the data stack.
  pop DE        ; Now DE holds the variable's address.
  ex DE, HL
  ld A, (HL)
  inc HL
  ld H, (HL)
  ld L, A
  ex DE, HL     ; Now DE (ToS) holds the variable's value.
  ret           ; Total: 64 Ts.

OP1:
  ...           ; Arg is in DE.
  ret           ; Total overhead: 10 Ts.
  
OP2:
  ld C, (HL)
  inc HL
  ld B, (HL)
  inc HL        ; Args are in BC, DE.
  ...
  ret           ; Total overhead: 36 Ts.
```
This is substantially faster than TTC in every respect (although calling and returning from functions will be slower -- I'll discuss this later).

### Summary so far

| Implementation | `NEXT` | `LIT` | `VAR` | `OP1` | `OP2` |
|----------------|-------:|------:|------:|------:|------:|
| TTC            |     39 |    76 |   103 |    39 |    49 |
| DTC (Stack)    |     10 |    46 |    64 |    10 |    36 |

## Interpreting Pointers or Direct Threaded Code (Non-stack-as-IP Version)

We might prefer to use the stack for data rather than for our instruction stream, in which case we end up with something like the following, where I've elected to use `SP` for the data stack, keep ToS in `BC`, and the instruction pointer in `HL`:
```
NEXT:
  ld E, (HL)
  inc HL
  ld D, (HL)
  inc HL
  ex DE, HL
  jp (HL)       ; Note: every instruction *must* start with 'ex DE, HL'!
                ; Total overhead: 38 Ts (including the extra 'ex DE, HL' in each instruction).
```
The remaining operations are essentially identical to those for the TTC implementation (i.e., have the same costs), the only differences being that `NEXT` in this DTC takes 38 Ts compared to 39 Ts for TTC, but at the cost of an extra byte per VM instruction -- a trade-off that hardly seems worthwhile.

### Summary so far

| Implementation | `NEXT` | `LIT` | `VAR` | `OP1` | `OP2` |
|----------------|-------:|------:|------:|------:|------:|
| TTC            |     39 |    76 |   103 |    39 |    49 |
| DTC (Stack IP) |     10 |    46 |    64 |    10 |    36 |
| DTC (Reg. IP)  |     38 |    75 |   102 |    38 |    48 |

## Naive compilation or Subroutine Threaded Code

STC is, you guessed it, a Forth-ism.  In this approach we forgo interpretation altogether and just emit executable machine code.  Here I've elected to use `HL` to hold ToS:
```
NEXT:
  ; Not needed!  Zero overhead.

LIT:
  push HL       ; Push previous ToS.
  ld HL, nn     ; ToS now holds the literal value.
                ; Total: 21 Ts.

VAR:
  push HL       ; Push previous ToS.
  ld HL, (vv)   ; ToS now holds the variable's value.
                ; Total: 27 Ts.
                
OP1:
  call op1      ; Implementation must return with `ret`.
                ; Total overhead: 27 Ts.

OP2:
  pop DE        ; Now args are in DE, HL.
  call op2      ; Implementation must return with `ret`.
                ; Total overhead: 37 Ts.
```

### Summary so far

| Implementation | `NEXT` | `LIT` | `VAR` | `OP1` | `OP2` |
|----------------|-------:|------:|------:|------:|------:|
| TTC            |     39 |    76 |   103 |    39 |    49 |
| DTC (Stack IP) |     10 |    46 |    64 |    10 |    36 |
| DTC (Reg. IP)  |     38 |    75 |   102 |    38 |    48 |
| STC (Compiled) |      0 |    21 |    27 |    27 |    37 |

Instruction stream size is slightly larger for STC than TTC (the most compact option): one extra byte for `LIT` and `VAR`, two or three extra bytes for `OP1` and `OP2`.  I would gladly accept that trade-off -- in my experience, data typically outweighs code by a substantial factor.

## The Scores on the Doors: Expressions

Returning to the example expression, `-x * (y + 1)` which we converted to
```
VAR x
NEG
VAR y
LIT 1
ADD
MUL
```
we compare the overheads of the different schemes outlined above:

| Implementation | Cost | Speedup |
|----------------|-----:|--------:|
| TTC            |  419 |    x1.0 |
| DTC (Stack IP) |  256 |    x1.6 |
| DTC (Reg. IP)  |  413 |    x1.0 |
| STC (Compiled) |  176 |    x2.4 |

The STC scheme has one further advantage not available to the others: many standard operators can be implemented in just a few bytes of Z80 machine code, in which case it might make more sense to just inline them rather than use `call`s.  For example:

```
NEG:
  ex DE, HL
  xor A
  ld L, A
  ld H, A
  sbc HL, DE    ; Total: 31 Ts, 6 bytes.
  
ADD:
  pop DE
  add HL, DE    ; Total: 25 Ts, 2 bytes.
```
Using `call`s, the total time for the expression would be 232 Ts; inlining, the total time would be 168 Ts (neither counting the cost of the `MUL`, which would be substantial).  

Note that the other schemes use `HL` as the instruction pointer or data stack pointer, which, due to `HL`'s privileged status on the Z80, makes implementing these operations more awkward.  For example:
```
; In schemes where HL is reserved for something important...
NEG:
  ld C, L
  ld B, H
  xor A
  ld L, A
  ld H, A
  sbc HL, DE
  ld L, C
  ld H, B
  [NEXT]        ; Total: 43 + [OP1] Ts.
  
ADD:
  ld A, C
  add A, E
  ld E, A
  adc A, B
  sub A, C
  ld D, A
  [NEXT]        ; Total: 24 + [OP2] Ts.
```
Interpretation really does jack up the costs, particularly for the simplest, most common operations.

## Implementing Basic Control Flow Structures

There are two standard imperative control-flow structures: `if-elif-else-end` and `while-continue-break-end` (where `continue` jumps back to the start of the loop and `break` exits the loop).  (The likes of `goto` and `gosub` are left as exercises for the sordid.)

### if-elif-else-end

The simple form of `if e1 st1 elif e2 st2 ... else st end`, where `st` stands for an arbitrary sequence of statements, is
```
  [[e1]]        ; `if e1 st1`
  JPZ -a-       ; Jump to -a- if the ToS is zero.
  [[st1]]
  JP -z-
-a-
  [[e2]]        ; `elif e2 st2`
  JPZ -b-
  [[st2]]
  JP -z-
-b-
  ; ...
-e-
  [[st]]        ; `else st`
-z-             ; End of `if` statement.
```

This is straightforward to generate in a single pass.  First, we have a variable `LastElseJp` holding the address of the previous `JPZ` for an `if` or `elif` which we fill in once we reach the next `elif` or `else`.  Second, we have a linked list `IfExitList` which links together all the `JP -z-` exits from the `if` and `elif` clauses.  Once we reach the `end`, we can fill in the `JP` targets in the `IfExitList`.

The instruction `JP nn` and `JPZ nn` instructions, under the compilation model, are just
```
JP:
  jp nn         ; Total: 10 Ts.
  
JPZ:
  ld A, L       ; Test ToS for zero.
  or H
  pop HL        ; Restore ToS, flags are unaffected.
  jp z, nn      ; Total: 18 Ts.
```

Note: a potentially useful micro-optimization would be to not emit the first `push HL` when generating code for an expression, assuming we immediately consume the result of any expression.  However, doing this would add a certain amount of complexity to the code generator.

### while-continue-break-end

The simple form of `while e st1 continue st2 break st3 end`, where the `continue` and `break` statements are optional and in any order, is
```
-a-
  [[e]]         ; `while e`
  JPZ -z-
  [[st1]]
  JP -a-        ; `continue`
  [[st2]]
  JP -z-        ; `break`
  [[st3]]
  JP -a-        ; `end`
-z-
```

Again, this is straightforward to generate in a single pass.  First we have a variable `LoopStart` holding the address if the loop entry point which we use to fill in the `JP -a-` instructions for `continue` and `end`.  Second, we have a `LoopExitList` which links together all the `JP -z-` exits from the `while` termination test and `break` statements.  Once we reach the `end`, we can fill in the `JP -z-` targets in the `LoopExitList`.

**Note** that `break` and `continue` are valid anywhere in the context of a loop, but `else` and `elif` are only valid in the immediate context of an `if` statement.  I plan to come back to this sort of detail a little later.

## Functions

Any real language has some support for functions -- hence many BASICs from the 1980s were not real languages.

How might we implement functions in our Basic-like language?  It turns out that we can do so easily and efficiently on the Z80 *if* we forgo recursion.  In my experience (and, as a functional programmer, it pains me to say this), few programmers out there understand or use recursion, so let's first see what happens if we *do* abandon support for recursion.  Indeed, this restriction works rather nicely with the single-pass compilation approach I'm advocating here: if we require that every function be defined before it is called (and don't admit functions as first class citizens -- this is a basic language, after all) then not only do we guarantee to have a symbol table entry ready for when we see a function call, but we prevent functions from calling themselves recursively.

### Supporting Recursion is Costly

Why is giving up recursion helpful when it comes to generating efficient Z80 code?  The answer is that the Z80 has absolutely poxy support for relative address indirection.  By that I mean that if you want to access an offset from a computed address, you have to use `ld r, (IX+n)` and `ld (IX+n), r`, each of which cost 19 T-states.  So accessing a 16-bit quantity like this costs, at minimum, 38 T-states.  This starts to add up quickly in common-case code.  To illustrate, the usual scheme is to use `IX` as a stack-frame pointer and to access function parameters and locals via `IX+n`.  Functions, using this approach, look something like this:
```
FunctionPrologue:       ; We assume that the function arguments have been pushed on to the stack.
  push IX               ; Save the previous frame pointer. 
  ld IX, -2m - 2        ; Assuming n 16-bit arguments and m 16-bit locals.
  add IX, SP            ; Now IX is the base of the new stack frame.
  ld SP, IX             ; Set the stack pointer.
  ...
  function body
  ...
FunctionEpilogue
  ld IX, 2m + 2
  add IX, SP
  ld SP, IX
  pop IX
  ret
```
The total cost of the prologue and epilogue is 107 T-states (not counting the `call` and `ret`) and every variable access costs 38 T-states.  Yikes!

### Abandoning Recursion

If we don't support recursion then every function parameter and local variable can have a fixed address, just like any other variable, and use the same `ld HL, (x)` and `ld (x), HL` instructions, at 16 T-states per access, and no function prologue or epilogue code is required.  Yes, we sacrifice expressive power, but this discussion is firmly rooted in the world of 1980s home computing where squeezing some speed out of the hardware was a priority.  That, plus the fact that Joe Programmer tragically wouldn't know one end of a recursive function from the other.  I digress.

Either way, we'd like to be able to write something like the following:
```
fn SqDiff x y:
  diff = (x + y) * (x - y)
  return diff
end

...
print SqDiff 4 3
```
and have it compile to something approximating the following:
```
SqDiff:
  ld HL, f_diff         ; The l-value of the assignment.
  push HL
  ld HL, (f_x)          ; `(x + y)`
  push HL
  ld HL, (f_y)
  pop DE
  add HL, DE
  push HL
  ld HL, (f_x)          ; `(x - y)`
  push HL
  ld HL, (f_y)
  pop DE
  xor A
  ex DE, HL
  sbc HL, DE
  pop DE                ; `(x + y) * (x - y)`
  call MUL
  pop DE                ; `diff = (x + y) * (x - y)`
  ex DE, HL
  ld (HL), E
  inc HL
  ld (HL), D
  ld HL, (diff)         ; `ret diff`
  ret
  
...
  ld HL, 4              ; print 4 3
  ld (f_x), HL
  ld HL, 3
  ld (f_y), HL
  call SqDiff
  call PRINT
```
Okay, somewhat flabby compared to hand-crafted code, but a veritable speed demon next to anything interpreted.

### Compiling Non-Recursive Functions

The basic points/steps involved are:
- functions introduce a new namespace, so the symbol table structure needs to support at least one level of nesting (global and local);
- we may need to surround the function definition with `jp EndOfFnDefn: [[fn definition]]: EndOfFnDefn`, so we'll need to record the address of that `jp` so we can fill in the jump target after compiling the function body;
- parsing the parameter list, we'll need to note the parameter names (these may shadow names in the global scope) and assign addresses for their values;
- to compile function calls elsewhere in the program, we'll need to record the number and addresses of parameters in the symbol table entry for the function;
- after compiling the function body, we need to return to the global namespace, to which we must also add a reference to the new function.

## Implementing Expressions

Forth gets around a lot of "problems" (for the compiler writer, anyway) by abandoning all error checking and requiring the user to convert all expressions into reverse Polish notation (i.e., args first, then operators).  Ugh.  Just unreadable.  Non write-only Forth programs tend to include stack diagram comments on every line.  Given that there will probably be more users than compiler writers, it behooves the compiler writer to put a little effort in to benefit said users.  That means we want proper expressions, supporting at the very least prefix and infix operators (with precedence) and parentheses for sub-expressions.

It turns out this is _not hard_.  The classic shunting yard algorithm is simple to implement.  The core of the shunting yard algorithm can be summarised as:
- if we see an 'atom' (a variable or constant) we emit code directly;
- if we see an operator, we emit code for any pending operators on the stack with higher precedence, then we push the new operator on to the stack;
- tidy up the loose ends when we're done.

For my minimalist non-rubbish language, I'm going to claim that the following regular expression supports just what we want:
```
  pfx* atom afx* ( ifx pfx* atom afx* )*
```
where `pfx` denotes a prefix operator, `afx` an affix (or postfix) operator, `ifx` an infix operator, and `atom` a variable, constant, or function application.  In the Wirthian style, we'll arrange things so that our compiler maintains sufficient context to identify errors such as mismatched parentheses.  Speaking of which, in this scheme we can treat
- `(` as a special prefix operator and
- `)` as a special affix operator.

Each operator needs the following things recorded in the symbol table: its name, its fixity (prefix or infix), and a pointer to the code to generate operator applications (this code should also handle things such as operator precedence).

## The Compilation State Machine

I'm going to describe a simple compiler as a state machine with a stack.  To start with, I'll cover expression compilation.  Following the regular expression above, we have two states: *AtPfx*, which must be followed by an atom or prefix operator, and *AtAtom*, which either terminates the expression or must be followed by an affix or infix operator.

| Token | AtPfx | AtAtom |
| ----- | ----- | ------ |
| *Pfx* | Push pfx gen | End expr |
| *Atom* | Gen atom <br> Gen pfxs <br> Go to *AtAtom* |
| *Afx* | Error! | Gen afx |
| *Ifx* | Error! | Push/gen ifx <br> Go to *AtPfx* |

To make this concrete, I present an example of how the expression `-(x + 3 * -y) ...` would be compiled.

| Token | State    | Action | Stack | Generated Code |
| ----- | -----    | ------ | ----- | -------------- |
| start | *        | Push state <br> Push `EndExpr, 0, EndPfx` <br> Go to *AtPfx* | `EndPfx`<br>`0 EndExpr` | |
| -     | *AtPfx*  | If *AtPfx* push `GenNeg` <br> If *AtAtom* treat as infix... | `GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| (     | *AtPfx*  | If not *AtPfx* close expr <br> Push `1 GenLPar, EndPfx` | `EndPfx`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| x     | *AtPfx*  | If not *AtPfx* close expr <br> Gen `VAR x`, ret | `1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | `VAR x` |
|       | *AtPfx*  | `EndPfx`: Go to *AtAtom* | `1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| +     | *AtAtom* | If not *AtAtom* then error! <br> Maybe gen ifx on stack <br> Push `GenAdd, 4, EndPfx` <br> Go to *AtPfx* | `EndPfx`<br>`4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| 3     | *AtPfx*  | If not *AtPfx* close expr <br> Gen `LIT 3`, ret | `4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | `LIT 3` |
|       | *AtPfx*  | `EndPfx`: Go to *AtAtom* | `4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| *     | *AtAtom* | If not *AtAtom* then error! <br> Maybe gen ifx on stack <br> Push `GenMul, 5, EndPfx` <br> Go to *AtPfx* | `EndPfx`<br>`5 GenMul`<br>`4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| -     | *AtPfx*  | If *AtPfx* push `GenNeg` <br> If *AtAtom* treat as infix... | `GenNeg`<br>`EndPfx`<br>`5 GenMul`<br>`4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| y     | *AtPfx*  | If not *AtPfx* close expr <br> Gen `VAR y`, ret | `EndPfx`<br>`5 GenMul`<br>`4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | `VAR y` |
|       | *AtPfx*  | `GenNeg`:  Gen `NEG`, ret | `5 GenMul`<br>`4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | `NEG` |
|       | *AtPfx*  | `EndPfx`: Go to *AtAtom* | `5 GenMul`<br>`4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
| )     | *AtAtom* | If not *AtAtom* then error! <br> If 1 < ToS then set replay ')', pop, ret <br> ... | `4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
|       | *AtAtom* | `GenMul`: Gen `MUL` | `4 GenAdd`<br>`1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | `MUL` |
| )     | *AtAtom* | If not *AtAtom* then error! <br> If 1 < ToS then set replay ')', pop, ret <br> ... | `1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | |
|       | *AtAtom* | `GenAdd`: Gen `ADD` | `1 GenLPar`<br>`GenNeg`<br>`EndPfx`<br>`0 EndExpr` | `ADD` |
| )     | *AtAtom* | If not *AtAtom* then error! <br> If 1 < ToS then set replay ')', pop, ret <br> If 0 = ToS then set replay ')', pop, ret <br> If 1 = ToS then pop, pop, ret | `EndPfx`<br>`0 EndExpr` | |
|       | *AtAtom* | `GenNeg`: Gen `NEG`, ret | `0 EndExpr` | `NEG` |
|       | *AtAtom* | `EndPfx`: Go to *AtAtom* | `0 EndExpr` | |
| ...   | *AtAtom* | If *AtAtom* then set replay `...`, pop, ret<br>Else ... | | |
|       | *AtAtom* | `EndExpr`: Pop state | | |

Note, _set replay ..._ means "next time, reprocess the most recently read token" -- in other words, do something without consuming the token.

The upshot of all the above is that from the input `-(x + 3 * -y) ...` we generate the following:
```
VAR x
LIT 3
VAR y
NEG
MUL
ADD
NEG
```

The code to implement the various tokens is simple:
```



...
Context:    dw 0  // The current parser state.
AtPfx       equ 1 // Parser states...
AtAtom      equ 2
...
ReplayTok:  dw 0  // Replay this token next if non-zero.
```
