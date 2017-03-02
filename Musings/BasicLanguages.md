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

## A digression regarding Forth

Horrible language, never liked it, with the sole redeeming feature of being somewhat quicker than the Basic interpreters of the day.  I will return to this at some point.  That said, the Forth philosophy of reaching for simplicity is worth emulating.

## What are we talking about?

I'm going to posit a Basic-like language with the following kinds of structures:

* Variables and constants.  I'm going to simplify the discussion for the most part by assuming that all variables are global and all quantities are 16-bit numbers.  Obviously 16-bits is too small for general use (32-bits would be fine), but it grounds the discussion: if you can't do well at 16-bits, you can't do well at 32-bits!  The "everything is global" assumption matches the Basic programming style of the day.  I'll discuss other options at some point.

* Assignment: `x = e`, where `e` denotes an expression.

* Expressions with prefix operators, infix operators with precedence, built-in functions, and parentheses: `-x * (y + abs(z))`

* `if e1 ... elif e2 ... else ... end`

* `while e ... end`

* Optionally `goto` and `gosub` and `:labels`, but these are neither here nor there.

* Built-in statements, such as `print e1, ...`

The syntax doesn't matter too much, although we'd obviously prefer to keep it Basic-like and LL(1) for ease of parsing (i.e., we require at most one token of look-ahead to decide what to do next).

User-defined functions can be added, but that's also something I intend to come back to in a bit.

## Virtual machines

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

## Interpreting tokens or Token Threaded Code

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
  ex de, HL     ; Now DE (ToS) holds the variable's value.
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
This is substantially faster than ITC in every respect (although calling and returning from functions will be slower -- I'll discuss this later).

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
