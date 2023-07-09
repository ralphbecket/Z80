# Unforth
Ralph Becket, 2020-06-01 - 2023-01-08

## The trouble with the Z80

This is a retro-computing project harking back to my time growing up with 
Sinclair computers in the UK, specifically the ZX81 and the ZX Spectrum.
These machines were as simple as could be, running a Z80 microprocessor.
The BASIC implementations were very slow, so any real work meant resorting
to something faster, typically assembly language.  The problem was that
the Z80 was a rather strange beast: it had one general purpose 8-bit
accumulator (the A register) and one general purpose 16-bit register (the
HL register pair).  There were several other registers available (B, C, D,
E and their pairings BC, DE, and the rather slow index registers IX and IY,
along with the flags register F and the stack pointer SP), but the 
instruction set around the extra registers was excitingly non-orthogonal.

## The trouble with Forth on the Z80

Forth is often touted as a good mid-point between BASIC and assembly.
Forth is a compact, stack-based language that, unfortunately,
is very difficult to implement efficiently on the Z80.  Another draw-back
of Forth is that it is a postfix language, Forth being purely stack oriented.
I find this extremely uncomfortable for real work.

Typical Z80 Forth implementations (e.g., Brad Rodriguez'
[Camel Forth](http://www.bradrodriguez.com/papers/camel80.txt))
represent a program as a sequence of pointers to machine code routines.
The DE register pair was usually used as the Forth instruction pointer
and every primitive Forth operation would finish by executing a `NEXT`
routine to fetch the next instruction address and jump to it.
The Camel Forth `NEXT` routine looks like this:

```
; This is the Z80 code equivalent to `goto *IP++`.
next:   MACRO           ; Note: DE is Forth IP.
        ex de,hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        ENDM
```

This takes a whopping 38 T-states (Z80 terminology for clock ticks).
The typical Z80 instruction takes around 4 to 16 T-states and a Forth
primitive is only a handful of Z80 instructions, so most Forth programs
on the Z80 spend most of their time just fetching the next instruction!

Things get worse: user-defined functions in Forth depend on an `ENTER`
and `EXIT` pre- and post-amble.  These incur a further 68 T-state and
48 T-state overhead respectively.

```
enter:  dec ix          ; push old IP on return stack
        ld (ix+0),d
        dec ix
        ld (ix+0),e
        pop hl			; param field adrs -> IP
        nexthl

exit:   ld e,(ix+0)		; pop old IP from return stack
        inc ix
        ld d,(ix+0)
        inc ix
        next
```

(Note: Forth separates the data and return stacks; Z80 implementations
used the Z80 stack, SP, as the data stack and the rather slow IX register 
as the return stack.)

Forth is faster than the BASIC interpreters of the day, but is still much
slower than pure assembly.  We can forgive Forth if we consider it to be 
an interpreted language (indeed, Forth is often referred to as a 'threaded
interpreted language' -- see Brad Rodriguez
[Moving Forth](http://www.bradrodriguez.com/papers/moving1.htm)
articles for a terrific reference if you want to know more).

## Sweet16 on the 6502

The 6502 crowd (the other mainstream 8-bit CPU of the day) would sometimes
mix pure assembly, which was aggressively 8-bit only on that CPU, with
in-line calls to `Sweet16`, a petite 16-bit register-based virtual machine
that would run at around a tenth the speed of hand-written assembly code.

## A comment on stack frames

Most high-level languages assume some kind of stack-frame mechanism for
holding function arguments and local variables.  The 6502 and Z80 were
unequivocally _bad_ at this sort of thing!  The Z80 was just slow at
this (hence every data access would be slow); the 6502 was quick only if
you restricted your stack size to 256 bytes (hence programs had to be
either short or slow).  Both CPUs could reasonably quickly access 16-bit
data at fixed addresses (particularly on the Z80) and since recursion was
rarely used on these machines, I argue that forgoing stack-frames in
favour of speed is the better trade-off for these CPUs.

## A comment on code size

Code size is rarely the limiting factor in my experience.  On those old
8-bit machines the available RAM was somewhere between 8 Kbytes and 
64 Kbytes: finding room for data was a far bigger problem.  Optimising
code density usually meant sacrificing quite a bit of performance.  The
Z80 and 6502 could just about manage half a MIPS with a following wind.
You really didn't want to give up speed unless you were struggling for
memory.

## Unforth

For years now I've been exploring the design space here, with a particular
eye on the Z80, although I believe my ideas could be ported to the 6502
without too much trouble.  I have dubbed my effort _Unforth_, viewing it
as a kind of counter argument to Forth on those machines.

My shopping list of goals for Unforth:
- it should be easy to bootstrap with the BASIC interpreters of the day;
- it should be quick and light;
- it should admit single-pass compilation;
- it should be possible to run it as a 'threaded' language
  (e.g., as a compact sequence of code pointers);
- it should be trivial to compile (so no interpretation overheads);
- compiled performance should aim to be within a factor of two of
  hand-written assembly language;
- the language should have a simple conceptual model.

Much thought and experimentation has led to me to the following conclusions:
- I hate postfix languages like Forth: Unforth will not be one of them!
- A single 16-bit implicit accumulator is optimal (neither the Z80 nor 6502
  are good with stacks and neither has registers sufficient to support any
  kind of efficient register machine model).
- No stack frames: variables are given fixed addresses and if you need
  recursion you have to roll your own stack frame abstraction.
- Optional functions -- an important goal was to come up with something you
  could bootstrap in the BASICs of the day without jumping through hoops.  I
  have extended Unforth to include functions, but these add far and away the
  most complexity to the implementation (although, mercifully, that complexity
  is orthogonal to the implementation of the rest of the language).

Here is an example Unforth program implementing the Euclidean algorithm
for calculating the greatest common divisor of two numbers.  A detailed
explanation can be derived from the sections below.
```
~ x ` Declare variables x and y.
~ y
\ gcd {
    x - y jz done jlt xlty
    : yltx     -> x j gcd   ` if y < x then x := x - y
    : xlty neg -> y j gcd   ` if x < y then y := y - x
    : done x ret            ` if x = y then x
}
```

## Unforth -- the specification

Here I'm going to use `x`, `y`, `z` to denote variables (i.e., 16-bit
quantities stored at fixed addresses), `123` to denote any constant, 
`W` to denote the implicit 16-bit accumulator, `Q` to denote an 
arbitrary label (i.e., code address), `IP` to denote the implicit 
instruction pointer (i.e., the address of the _next_ instruction to execute),
`SP` to denote the implicit stack pointer (which grows from high addresses
to low addresses).  Unforth source code is a sequence of space separated
tokens, terminated by an ASCII NUL (0) with the proviso that a backquote
starts a comment that extends to the end of the current line.  Tokens
fall into the following exclusive categories:
- _directives_ (e.g., variable and label definitions);
- _constants_ (i.e., numbers);
- _labels_ (i.e., code addresses);
- _immediate operators_ (that take no argument);
- _prefix operators_ (taking a single argument);
- _infix operators_ (taking left and right arguments).
Most operators are 16-bit.  Since 8-bit operations are important (e.g.,
string handling), in the Unforth convention 8-bit operations are
distinguished by a trailing `.`.

In the Z80 column of the specification I use `HL` as the implicit working
accumulator, `W`.

### Constants and variables

| Unforth       | C Pseudocode              | Z80 |
| -------       | ------------              | --- |
| `123`         | `W = 123`                 | `ld HL, 123` |
| `x`           | `W = *x`                  | `ld HL, (x)` |
| `& x`         | `W = x`                   | `ld HL, x` |
| `& L`         | `W = L`                   | `ld HL, L` |
| `@`           | `W = *W`                  | `ld A, (HL) : inc HL : ld H, (HL) : ld L, A` |
| `@.`          | `W = *(byte*)A`           | `ld L, (HL)` |
| `-> 123`      | `*123 = W`                | `ld (123), HL` |
| `->. 123`     | `*123 = (byte)W`          | `ld A, L : ld (123), A` |
| `-> x`        | `*x = W`                  | `ld (x), HL` |
| `->. x`       | `*x = (byte)W`            | `ld A, L : ld (x), A` |

### Arithmetic and logic

Some costly operations (e.g., multiplication and division) would be implemented
in a library.  In 8-bit operations (distinguished by a trailing `.`), the 
upper 8-bits of the accumulator are taken to be undefined.

| Unforth       | C Pseudocode              | Z80 |
| -------       | ------------              | --- |
| `+ 123`       | `W += 123`                | `ld DE, 123 : add HL, DE` |
| `- 123`       | `W -= 123`                | `ld DE, 123 : xor A : sbc HL, DE` |
| `* 123`       | `W *= 123`                | `ld DE, 123 : call __mul__` |
| `*u 123`      | `W = (unsigned)W * 123`   | `ld DE, 123 : call __umul__` |
| `/ 123`       | `W /= 123`                | `ld DE, 123 : call __div__` |
| `/u 123`      | `W = (unsigned)W / 123`   | `ld DE, 123 : call __udiv__` |
| `+ x`         | `W += *x`                 | `ld DE, (x) : add HL, DE` |
| `- x`         | `W -= *x`                 | `ld DE, (x) : xor A : sbc HL, DE` |
| `* x`         | `W *= *x`                 | `ld DE, (x) : call __mul__` |
| etc.          |                           | |
| `neg`         | `W = -W`                  | `ex DE, HL : ld HL, 0 : xor A : sbc HL, DE` |
| `cpl`         | `W = ~W`                  | `ld A, L : cpl : ld L, A : ld A, H : cpl : ld H, A` |
| `1+`          | `W += 1`                  | `inc HL` |
| `2+`          | `W += 2`                  | `inc HL : inc HL` |
| `1-`          | `W -= 1`                  | `dec HL` |
| `2-`          | `W -= 2`                  | `dec HL : dec HL` |
| `<<`          | `W <<= 1`                 | `add HL, HL` |
| `>>`          | `W >>= 1`                 | `sra H : rr L` |
| `>>u`         | `W = W >> 1 & 0x7f`       | `srl H : rr L` |

(and so on).

### Control flow

| Unforth       | C Pseudocode              | Z80 |
| -------       | ------------              | --- |
| `j Q`         | `goto Q`                  | `jp Q` |
| `jz Q`        | `if (W == 0) goto Q`      | `ld A, L : or H : jp z, Q` |
| `jnz Q`       | `if (W != 0) goto Q`      | `ld A, L : or H : jp nz, Q` |
| `jlt Q`       | `if (W < 0) goto Q`       | `bit 7, H : jp nz, Q` |
| `jge Q`       | `if (W >= 0) goto Q`      | `bit 7, H : jp z, Q` |
| `j@`          | `goto W`                  | `ld A, (HL) : inc HL : ld H, (HL) : ld L, A : jp (HL)` |
| `call Q`      | `Q()`                     | `call Q` |
| `ret`         | `return`                  | `ret` |

### Directives

| Unforth       | C Pseudocode              | Comment |
| -------       | ------------              | ------- |
| `: Q`         | `Q:`                      | Define a label. |
| `> Q`         |                           | Declare a forward reference to a label Q (see below.) |
| `{`           | `{`                       | Open a new naming scope. |
| `}`           | `}`                       | Close the current naming scope. |
| `~ x`         | `int x;`                  | Declare a variable. |
| `! k 123`     | `#define k 123`           | Declare a named constant. |
| `~! x 123`    | `extern int x;`           | Declare an external variable at the given address. |
| `# 123`       | `__inline__ 123`          | Define a byte of inline assembly code (see below). |

- All names defined within braces `{ ... }` are local to that scope.
- All previously defined or declared names are visible within that scope.
- Scopes may be nested.
- All label references within a scope must be resolved by the end of the
  scope _except_ for previously declared forward references.
- Control flow can use implicit forward label references as long as those
  references are either explicitly declared as forward
  references in an outer scope or are defined properly within the scope.
- Names cannot shadow one another.

Why have scoping in what is a glorified assembly language?  Because
programming in a single namespace is a royal pain.  Some examples:
```
: foo { ~ x : bar }
` Good: both x and bar are defined in scope.

: foo { j bar }
` Bad: bar is not an external forward reference and is not defined in scope.

> bar : foo { j bar } : bar
` Good: the nested scope references externally declared forward reference bar.

: abs { jge done neg : done ret }
` Good: neg is a local forward reference defined before the end of the scope.
```

A point worth highlighting: implicit forward references, as in the `abs`
example above, require the Unforth parser to understand where a label is
expected vs where a variable or constant is expected.

### The `#` directive

This allows one to define in-line Z80 machine code as a sequence of 
bytes optionally interspersed with variables and labels
which will be replaced with their addresses.

For example, `# 125 # 215` inlines the following instructions:
```
    ld A, L
    rst 16
```
which, on the ZX Spectrum, has the effect of printing the character in the
low 8 bits of the Unforth accumulator.

(To do: include a more interesting example involving variables and labels.)

## Execution

### "Threaded code" on the Z80 stack

Since Unforth mostly doesn't use the Z80 stack, we can employ a neat
trick.  When the Z80 executes a `ret`, it just pops the top value off
the stack and jumps to it.  This takes a modest 10 T-states (cf. 38
T-states for Forth's `NEXT`).  Consequently we can use a compact
Forth-style representation that will execute quickly: a stream of
pointers to Unforth primitives, interspersed with constants (including
variable addresses and label addresses).  For example, the `gcd`
function,
```
~ x
~ y
: gcd {
    x - y jz done jlt xlty
    : yltx     -> x j gcd   ` if y < x then x := x - y
    : xlty neg -> y j gcd   ` if x < y then y := y - x
    : done x ret            ` if x = y then x
}
```
might be represented like this (I'm using assembler notation here for 
exposition, words in capitals denote Unforth operations):
```
x:      ds 2
y:      ds 2
gcd:    dw VAR, x, SUBVAR, y, JZ, done, JLT, xlty
yltx:   dw SETVAR, x, J, gcd
ylty:   dw NEG, SETVAR, y, J, gcd
done:   dw VAR x, RET
```
The Unforth operations might be implemented like this on the Z80 (I'm
taking some liberties with the op-codes for the sake of brevity):
```
VAR:    pop HL : ld HL, (HL) : ret
SUBVAR: pop DE : ld DE, (DE) : xor A : sbc HL, DE : ret
JZ:     pop DE : ld A, L : or H : ret z : ld SP, DE : ret
; ... and so on.
```
Not quite as good as compiled code and a separate Forth-style stack
is required for call/return, but programs would be quite compact.

(Note: code implemented in this style would have to run with interrupts
disabled since an interrupt would destroy the instruction sequence by
pushing the address for the interrupt handler to return to on to the stack,
overwriting part of the Unforth token stream.)

### "Token threaded code"

Just as an observation, provided Unforth has fewer than 256
primitives, we could compress the above encoding using a single byte
for each operator (and we could do something similar for the constants
if there were fewer than 256 variables and labels).  You probably
wouldn't want to execute this representation, but it would be easy to
store (e.g., on tape or in magazine listings, which were common back
in the day) and it would be trivial to compile or expand into the
"threaded code" version above or the compiled version below.

### Compiled code on the Z80

The fastest code would obviously be the compiled form.  This is slightly
less compact than the threaded code representation: eyeballing the 
operator implementations above, I estimate the average operation would
take up somewhere between three to five bytes (compared to two or four
bytes in the threaded representation).

## Implementation notes

### Tokenisation

A Unforth program, as with Forth, is a strictly white-space separated
sequence of tokens.  A token is any contiguous non-whitespace sequence
of characters.

To speed look-ups, a one-byte hash is computed for each token as it is
scanned (the symbol table is a simple, linear array structure).

```impl
SrcPtr      ds 2            ; Next source code location to scan.

; Note: this collection of fields must form a symbol table entry.

TokEntry    equ $
TokHash:    ds 1            ; Token hash for lookups.
TokLen:     ds 1            ; Token length.
TokStart:   ds 2            ; Token start in source code.
TokKind:    ds 1            ; Token kind (e.g., label, var, etc.).
TokDatum:   ds 1            ; Token value (e.g., address).
TokSym:     ds 2            ; Token symbol table entry address.

ScanTok:
    ld HL, (SrcPtr)
SkipWS:
    ld A, (HL)
    and A
    jr z, AtEof             ; The source code is NUL terminated.
    cp ' '+1
    jr nc, AtTokStart       ; Skip over whitespace.
    inc HL
    jr SkipWS
AtTokStart:
    ld (TokStart), HL
    add A, A
    ld C, A                 ; This is going to be our hash.
    ld B, 1                 ; This is going to be our length.
TokLoop:
    inc HL
    ld A, (HL)
    cp ' '+1                ; Whitespace marks the end of the token.
    jr c, AtTokEnd
    xor C                   ; Calculate a very simple hash.
    add A, A
    ld C, A
    inc B                   ; Increment the length counter.
    jr TokLoop
AtTokEnd:
    ld A, B
    ld (TokLen), A
    ld A, C
    inc A                   ; Hash must be non-zero.
    ld (TokHash), A
```

### The symbol table

The heart of the compiler is the symbol table.  Because string matching
is slow, I opt to calculate a simple one-byte hash of each identifier
to speed symbol table searches.

In my implementation I reserve a hash of zero to indicate the end of
the symbol table (which implies all other hashes must be made non-zero).

The structure of my symbol table is as follows:

| Bytes | Name | Explanation |
| ----- | ---- | ----------- |
| 1 | SymHash   | The hash of the identifier. |
| 1 | SymLen    | The length of the identifier. |
| 2 | SymStart  | Pointer to the first occurrence of the symbol in the source code. |
| 1 | SymKind   | The kind of symbol (e.g., constant, variable, label, etc.) |
| 2 | SymDatum  | The symbol data (e.g., variable or label address) |

```impl
SymHash:    equ 0
SymLen:     equ 1
SymStart:   equ 2
SymKind:    equ 4
SymDatum:   equ 5
SymSize:    equ 7
```

The symbol table is implemented as an array of consecutive entries at
decreasing addresses (i.e., it grows downwards in memory).  The first
entry is a dummy marking the start of the array.  The table is scanned
forwards from the most recently added entry.

### Searching the symbol table

Matching a symbol in Z80 looks like this (it could be sped up, this is written
more or less for clarity):
```impl
FindSym:
    ld IX, (SymLast)        ; The start of the symbol table.
    ld BC, SymSize
    ld A, (TokHash)         ; The hash of the token we are looking up.
    ld E, A
    ld A, (TokLen)          ; The length of the token.
    ld D, A
SymLoop:
    ld A, (IX + SymHash)
    and A
    jr z, NotFound
    cp E
    jr nz, NotAMatch
CmpLens:
    ld A, (IX + SymLen)
    cp D
    jr z, NotAMatch
CmpStrs:
    push BC
    push DE
    ld HL, (TokStart)
    ld B, D
    ld E, (IX + SymStart + 0)
    ld D, (IX + SymStart + 1)
CmpLoop:
    ld A, (DE)
    cp (HL)
    jr nz, CmpEnd           ; Carry flag is clear.
    inc HL
    inc DE
    djnz CmpLoop
    scf                     ; Carry flag is set.
CmpEnd
    pop DE
    pop BC
    jr nc, Found
NotAMatch:
    add IX, BC              ; IX += SymSize.
    jr SymLoop
NotFound:
    ...                     ; See TryDecimal below.
Found:
    ld (TokSym), IX
    ld A, (IX + SymKind)
    ld L, (IX + SymDatum + 0)
    ld H, (IX + SymDatum + 1)
    ld (TokDatum), HL
    ret
```

### Symbol table lookup failures

We have two possible cases here: the token we just looked for is a constant
(decimal or otherwise) or the token is a new symbol.

### Parsing decimal constants

One could imagine supporting other number bases, but let's go with just 
decimal for now:
```impl
NotAMatch:
TryDecimal:
    ld A, (TokLen)
    ld B, A
    ld HL, 0                ; N = 0
    ld DE, (TokStart)
DecimalLoop:
    ld A, (DE)
    cp ' '+1
    jr c, DecimalEnd
    sub A, '0'
    jr c, NotDecimal
    cp 10
    jr nc, NotDecimal
    add HL, HL              ; N *= 10
    ld C, L
    ld B, H
    add HL, HL
    add HL, HL
    add HL, BC
    add A, L                ; N += A
    ld L, A
    adc A, H
    sub A, L
    ld H, A
    inc DE
    jr DecimalLoop
DecimalEnd:
    ld A, KindConst
    ld (TokKind), A
    ld (TokDatum), HL
    ret
NotDecimal:
    ...                     ; See NewSym below.
```

### New symbols

If a token can't be found in the symbol table and it isn't a constant
literal then it has to be a new symbol, which we simply add to the symbol
table.

```impl
NewSym:
    ld HL, (SymLast)
    ld BC, SymSize
    xor A
    sbc HL, BC
    ex DE, HL
    ld IXL, E
    ld IXH, D
    ld HL, TokEntry
    ldir
    ret
```

### Compiler state

The compiler really only needs a small amount of state:
- the current position in the source code (`SrcPtr`);
- the pointer to the most recently added symbol table entry (`SymLast`);
- the current token details (`TokKind`, `TokDatum`, `TokSym`);
- the next address to write generated object code (`GenTop`);

Note: variables are assigned addresses at the end of the object code
after the source code has been compiled.

### Code generation

Several symbols directly generate code; some require an argument; and
some are 'directives' (e.g., for declaring variables and labels).

(In what follows, a comment `SMC!` indicates self modifying code.)

For non-directives, we basically need to append some template machine
code to the compiled object code.  We have three routines for this:
- one for operators taking a parameter where the value is known (e.g.,
  a constant);
- one for operators where the value is not yet known (e.g., a forward
  label reference or a variable reference);
- and one for operators that do not take any parameter.

Each of the code generation calls will be followed the code template
to be copied.  A `call` on the Z80 pushes the following return
address on the stack, which is how our code generation routines will
obtain the template address.

Each code generation template looks like this:
- a length byte;
- if needed, a byte containing the negative offset from the end of the
  template for any argument;
- the template code itself.

For the case where the template takes a currently unknown value
parameter (e.g., a variable reference or forward reference to a label)
then we generate a linked list of pointers through the object code.
Once the value becomes known (e.g., the label is defined or the variable
is allocated an address) then we traverse the linked list substituting
the link pointers with the now-known value.

```impl
GenTop:     ds 2            ; The next address for object code generation.

GenOpNoArg:
    pop HL                  ; HL is the template address.
    ld C, (HL)
    ld B, 0                 ; BC is template length.
    inc HL
    ld DE, (GenTop)
    ldir                    ; Copy the template code to the object code.
    ld (GenTop), DE
    jp (HL)

GenOpConst:
    pop HL                  ; HL is the template address.
    ld C, (HL)
    ld B, 0                 ; BC is template length.
    inc HL
    ld A, (HL)              ; A is -ve offset from end for arg.
    ld DE, (GenTop)
    ldir                    ; Copy the template code to the object code.
    ld (GenTop), DE
    push HL                 ; (SP) is post-code gen return address.
    ld L, A
    ld H, $ff               ; HL is -ve offset from end for arg.
    add HL, DE              ; HL is addr of arg in object code.
    ex DE, HL
    ld HL, TokData          ; Fill in arg from (TokData).
    ldi
    ldi
    ret

GenOpFwdRef:
    pop HL                  ; HL is the template address.
    ld C, (HL)
    ld B, 0                 ; BC is template length.
    inc HL
    ld A, (HL)              ; A is -ve offset from end for arg.
    ld DE, (GenTop)
    ldir                    ; Copy the template code to the object code.
    ld (GenTop), DE
    push HL                 ; (SP) is post-code gen return address.
    ld L, A
    ld H, $ff               ; HL is -ve offset from end for arg.
    add HL, DE              ; HL is addr of arg in object code.
    ex DE, HL
    ld A, (IX + SymDatum + 0); Extend linked list from (IX + SymDatum).
    ld (IX + SymDatum + 0), L
    ld (HL), A
    ld A, (IX + SymDatum + 1)
    ld (IX + SymDatum + 1), H
    inc HL
    ld (HL), A
    ret
```

#### Code generation macroes

Here I'm going to define some macroes to simplify code generation.  I am
using Simon Brattel's Zeus assembler syntax here:

```impl
GenOpNoArgM: macro(code)
    call GenOpNoArg
        db CodeEnd - CodeStart
    CodeStart:
        code
    CodeEnd:
endm

GenOpConstM: macro(code)
    call GenOpConst
        db CodeEnd - CodeStart
        db [smc] - CodeEnd  ; [smc] is defined in code.
    CodeStart:
        code
    CodeEnd:
endm

GenOpFwdRefM: macro(code)
    call GenOpFwdRef
        db CodeEnd - CodeStart
        db [smc] - CodeEnd  ; [smc] is defined in code.
    CodeStart:
        code
    CodeEnd:
endm
```

#### Compiling a constant

```
    ; Gen 123
    GenOpConstM({
        ld HL, [smc]
    })
```

#### Compiling a variable

```
    ; Gen x
    GenOpFwdRefM({
        ld HL, ([smc])
    })
```

#### Compiling a nullary operator

Example:
```
    ; Gen 1+
    GenOpNoArgM({
        inc HL
    })
```

Example: 
```
    ; Gen neg
    GenOpNoArgM({
        ex DE, HL
        ld HL, 0
        xor A
        sbc HL, DE
    })
```

#### Compiling an operator taking a constant

Example:
```
    ; Gen + const
    GenOpConstM({
        ld DE, [smc]
        add HL, DE
    })
```

#### Compiling an operator taking a forward reference

Example:
```
    ; Gen + var
    GenOpFwdRefM({
        ld DE, ([smc])
        add HL, DE
    })
```

#### Compiling directives: comments

```impl
    ; Comment: skip to end of line.
    ld HL, (SrcPtr)
Loop:
    ld A, (HL)
    and A           ; Check for EOF.
    jr z, Done
    inc HL
    cp '\n'
    jr nz, Loop
Done:
    ld (SrcPtr), HL
    ret
```

### The compilation loop




