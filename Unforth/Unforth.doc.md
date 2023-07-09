# Unforth
** Ralph Becket, 2022 **


## Introduction

*Unforth* is a compiled language for the Z80 microprocessor.  The main design
goals were to produce something that would run quickly (ideally within a factor
of two of hand-written assembly language); that could reasonably be
implemented, in the first place, via the ubiquitous BASIC interpreters of the
day; and that would be way more readable than Forth (which is very clever and
utterly unreadable).

The name is a reaction to Forth which existed in many forms for the Z80.  As I
have indicated, I have always found Forth programs nearly impossible to
follow.  Worse, Forth on the Z80 is extremely slow, with implementations
often spending much more time in the interpreter operations (NEXT, ENTER,
and EXIT) than doing actual work.

(As an aside, it seems as though I may have re-invented an even older systems
language called *Mary*.)

The compiler, written in Z80 assembler for Simon Brattel's Zeus Assembler,
comes to less than 3 Kbytes including the Unforth run-time library.


## A Motivating Example

Here, without explanation, is a simple Unforth function to calculate the
greatest common divisor of two numbers using Euclid's algorithm:

    \ x , y gcd {
        : loop
        x - y
        ifz x=y                 ; if x - y = 0 goto x=y
        iflt x<y                ; if x - y < 0  goto x<y
        : y<x     -> x  loop    ; x = x - y
        : x<y neg -> y  loop    ; y = y - x
        : x=y x                 ; return x
    }
    ; Call our function.
    18 , 8 gcd

This compiles to the equivalent assembly language:

        jp _past_gcd
    gcd: 
        ; Function prologue for two parameters.
        ld (y), HL                  ; Save y parameter.
        pop DE                      ; Preserve return address.
        pop HL : ld (x), HL         ; Save x parameter.
        push DE                     ; Restore return address.
    loop:
        ld HL, (x)                  ; x - y
        ex DE, HL
        ld HL, (y)
        and A
        sbc HL, DE
        jp z, xeqy                  ; if x - y = 0 goto xeqy
        bit 7, H
        jp nz, xlty                 ; if x - y < 0  goto xlty
    yltx:
        ld (x), HL                  ; x = x - y
        jp loop
    xlty:
        xor A : sub L : ld L, A : sbc A, A : sub A, H : ld H, A
        ld (y), HL                  ; y = y - x
        jp loop
    xeqy:
        ld HL, (x)                  ; return x
        ret
    _past_gcd:

        ; Call our function.
        ld HL, 18
        push HL
        ld HL, 8
        call gcd

While hand-written assembly langauge would be a bit faster, I expect this is
within a factor of two of the optimal implementation.

## Grammar

In what follows 123 denotes an arbitrary numerical constant; `"abc"` denotes an
arbitrary string constant; `x`, `y`, `z` denote arbitrary variables; `L`, `L1`,
`L2`, `L3` denote arbitrary control flow labels; `f`, `f1`, `f2`, `f3` denote
arbitrary function names; `~` denotes an arbitrary postfix operator; `*`
denotes an arbitrary infix operator.

Unforth's grammar is shown below.  It is designed for single-pass compilation.
Tokens are non-whitespace characters separated by whitespace (e.g., `x + 1` is
three tokens, `x+1` is a single token).  Comments are considered whitespace and
extend from a `;` token to the end of the line.

    Unforth ::= (LabelDef | Expr | CtrlFlow | FnDef)*

    LabelDef ::= ':' L

    CtrlFlow ::= L | 'ifnz' L | 'ifz' L | 'iflt' L | f

    FnDef ::= '\' x ',' y ',' z f '{' Unforth '}'

    Expr ::= Atom (~ | * Atom | Assgt)*

    Atom ::= 123 | x | AddrOf | '(' Expr ')'

    AddrOf ::= '&' (x | L | f)

    Assgt ::= '->' x

Numerical constants take an optional leading minus sign followed either by
one or more decimal digits or a `#` and one or more hexadecimal digits.

String constants are zero terminated byte sequences whose "value" is the
address of the first byte.  In the string a `#` indicates an escaped
character and must be followed by exactly two hex digits.

## Scope and Forward References

With two exceptions, all names must be defined before they are used.

The following cases define names:

- `...expr... -> x` defines a new variable `x` *provided* `x` has not
  previously been defined for the current scope (in either case it denotes an
  assignment).

- `& x` denotes the address of variable (or function parameter) `x` which must
  already be visible in the currrent scope.

- `: L` defines a new control flow label, `L`.

- `& L` denotes the address of label `L`.  If `L` is a new symbol in the
  current scope then it defines a forward reference to `L` which must be
  defined later in the current scope.

- `L`, `...expr... ifnz L`, `...expr... ifz L`, and `...expr... iflt L` where
  `L` has not yet been defined for the current scope, denotes a (conditional)
  forward jump to `L` which is required to be defined later in the same scope
  (had `L` already been defined its appearance in the program would mean a
  backwards jump).

- `\ x , y , z f { ...body... }` defines a function `f` taking parameters 
  `x`, `y`, `z`.  Labels and variables defined inside the function *are not*
  visible *outside* the function body.  The funtion name is not visible *in*
  the function body (hence direct recursion is not supported in Unforth).  The
  parameters and any variables visible at the point of the function definition
  are visible in the function body.

Note that function definitions may be nested.

## Operational Semantics

Unforth is based around a simple 16-bit virtual machine model that maps well to
the Z80.  The virtual machine has one primary register, `V`, an auxiliary
register, `U`, and a stack indexed by a stack pointer, `SP`.

We present each operation in Unforth, its equivalent in C, and how it might
be implemented in Z80 assembly language (note that C statements are terminated
by semicolons while Z80 instructions are separated by colons).  The Z80 code
here assumes `U` is held in the `DE` register pair, `V` is held in the `HL`
register pair, and `SP` is the Z80's `SP` register, typically accessed via
`push` and `pop` instructions.

### Numerical constant
A constant (a decimal number, hex number, or a string) simply loads the
corresponding value into the primary `V` register.

| **Unforth**          | `123                                     ` |
| :--- | :--- |
| **C**                | `V = 123;                                ` |
| **Z80**              | `ld HL, 123                              ` |

### String constant
String constants are stored inline, with a terminating `NUL`, in the object
code, which simply jumps over the string data before loading the string start
address into the `V` register.

| **Unforth**          | `"abc"                                   ` |
| :--- | :--- |
| **C**                | `tmp = "abc"; V = &tmp;                  ` |
| **Z80**              | `    jp _past_str123                     ` |
|                      | `_str123:                                ` |
|                      | `    db "abc", 0                         ` |
|                      | `_past_str123:                           ` |
|                      | `    ld HL, _str123                      ` |

### Variable load
Variables (and function parameters) are assigned fixed addresses.
The appearance of a variable simply loads the value at that address
into the `V` register.

| **Unforth**          | `x                                       ` |
| :--- | :--- |
| **C**                | `V = x;                                  ` |
| **Z80**              | `ld HL, (x)                              ` |

### Variable address
We can take the address of a variable, in which case that is loaded
into the `V` register (as opposed to the contents at that address).

| **Unforth**          | `& x                                     ` |
| :--- | :--- |
| **C**                | `V = &x;                                 ` |
| **Z80**              | `ld HL, x                                ` |

### Variable assignment

| **Unforth**          | `...expr... -> x                         ` |
| :--- | :--- |
| **C**                | `V = ...expr...;                         ` |
| **Z80**              | `ld (x), HL                              ` |

### Label definition
A label definition sets a target for control flow operations.

| **Unforth**          | `: L1                                    ` |
| :--- | :--- |
| **C**                | `L1:                                     ` |
| **Z80**              | `L1:                                     ` |

### Jump to label
Just naming a label denotes an unconditional jump to that label.
If the label has not yet been defined, this is a forward reference.

| **Unforth**          | `L1                                      ` |
| :--- | :--- |
| **C**                | `goto L1;                                ` |
| **Z80**              | `jp L1                                   ` |

### Jump if non-zero
Jump to a label if `V` is non-zero.
If the label has not yet been defined, this is a forward reference.

| **Unforth**          | `...expr... ifnz L1                      ` |
| :--- | :--- |
| **C**                | `...expr...; if (V) goto L1;             ` |
| **Z80**              | `...expr... : ld A, L : or H : jp nz, L1 ` |

### Jump if zero
Jump to a label if `V` is zero.
If the label has not yet been defined, this is a forward reference.

| **Unforth**          | `...expr... ifz L1                       ` |
| :--- | :--- |
| **C**                | `...expr...; if (!V) goto L1;            ` |
| **Z80**              | `...expr... : ld A, L : or H : jp z, L1  ` |

### Jump if less than zero
Jump to a label if `V` is less than zero.
If the label has not yet been defined, this is a forward reference.

| **Unforth**          | `...expr... iflt L1                      ` |
| :--- | :--- |
| **C**                | `...expr...; if (V < 0) goto L1;         ` |
| **Z80**              | `...expr... : bit 7, H : jp nz, L1       ` |

### Label address
Put the address of label `L1` in `V`.
If the label has not yet been defined, this is a forward reference.

| **Unforth**          | `& L1                                    ` |
| :--- | :--- |
| **C**                | `V = &L1;                                ` |
| **Z80**              | `ld HL, L1                               ` |

### Function address
Put the address of function `f1` in `V`.
The function must have been defined previously.

| **Unforth**          | `& f1                                    ` |
| :--- | :--- |
| **C**                | `V = &f1;                                ` |
| **Z80**              | `ld HL, f1                               ` |

### Immediate operator
Any immediate operator can manipulate `V` (and possibly `U`).

| **Unforth**          | `~                                       ` |
| :--- | :--- |
| **C**                | `V = ~V;                                 ` |
| **Z80**              | `...ops for ~...                         ` |

### Infix operator
An infix operator is always followed by an atom.
The value in `V` is written to `U`.
The right hand argument (an atom) is written to `V`.
Then the infix operator is applied, putting its result in `V` (and possibly
changing `U`).

| **Unforth**          | `...expr... * atom                       ` |
| :--- | :--- |
| **C**                | `...expr...; U = V; atom; V *= U         ` |
| **Z80**              | `...expr... : ex DE, HL : atom : ...ops for *...` |

### Sub-expression
Here `*` stands for any infix operator.

| **Unforth**          | `...expr... * ( ...sub-expr... )         ` |
| :--- | :--- |
| **C**                | `...expr...; *--SP = U; ...sub-expr...; U = *SP++; V *= U` |
| **Z80**              | `...expr... : push DE : ...sub-expr... : pop DE : ...ops for *...` |

### Function call (no parameters)
A function must be defined before it can be called.
Simply naming the function denotes a function call.

| **Unforth**          | `f1                                      ` |
| :--- | :--- |
| **C**                | `f1()                                    ` |
| **Z80**              | `call f1                                 ` |

### Function call (one parameter)
A single-parameter function call passes the argument in `V`.

| **Unforth**          | `...expr1... f1                          ` |
| :--- | :--- |
| **C**                | `f1(...expr1...)                         ` |
| **Z80**              | `...expr1... : call f1                   ` |

### Function call (several parameters)
A multi-parameter function call passes the final argument in `V`
and the preceding arguments on the stack (the `,` operator
simply pushes `V` on the stack).

| **Unforth**          | `...expr1... , ...expr2... , ...expr3... f1` |
| :--- | :--- |
| **C**                | `f1(...expr1..., ...expr2..., ...expr3...)` |
| **Z80**              | `    ...expr1... : push HL               ` |
|                      | `    ...expr2... : push HL               ` |
|                      | `    ...expr3... : call f1               ` |

### Push
Pushes `V` on to the stack.  Normally used to pass arguments in a function call.

| **Unforth**          | `,                                       ` |
| :--- | :--- |
| **C**                | `*--SP = V;                              ` |
| **Z80**              | `push HL                                 ` |

### Pop
Copies `V` to `U` and pops the top of the stack into `V`.  
pop

| **Unforth**          | `U = V; V = *SP++;                       ` |
| :--- | :--- |
| **C**                | `ex DE, HL : pop HL                      ` |

### Function definition (no parameters)
Nullary functions are simple.

| **Unforth**          | `\ f1 { ...body... }                     ` |
| :--- | :--- |
| **C**                | `void f1() { ...body... }                ` |
| **Z80**              | `    jp _past_f1                         ` |
|                      | `f1: ...body...                          ` |
|                      | `    ret                                 ` |
|                      | `_past_f1:                               ` |

### Function definition (one parameter)
Unary functions start by assigning `V` to their single parameter variable.

| **Unforth**          | `\ x f1 { ...body... }                   ` |
| :--- | :--- |
| **C**                | `void f1(short x) { ...body... }         ` |
| **Z80**              | `    jp _past_f1                         ` |
|                      | `f1: ld (x), HL                          ` |
|                      | `    ...body...                          ` |
|                      | `    ret                                 ` |
|                      | `_past_f1:                               ` |

### Function definition (several parameters)
Multi-parameter functions have a slightly more complex prologue because,
while all but the last argument value is on the stack (the last argument
being in `V`), the return address is at the top of the stack and must be
preserved for when the function returns.

| **Unforth**          | `\ x y z f1 { ...body... }               ` |
| :--- | :--- |
| **C**                | `void f1(short x, short y, short z) { ...body... }` |
| **Z80**              | `    jp _past_f1                         ` |
|                      | `f1: pop BC                              ` |
|                      | `    ld (z), HL                          ` |
|                      | `    pop HL : ld (y), HL                 ` |
|                      | `    pop HL : ld (x), HL                 ` |
|                      | `    push BC                             ` |
|                      | `    ...body...                          ` |
|                      | `    ret                                 ` |
|                      | `_past_f1:                               ` |



## Primitive operators

Recall that infix operators (i.e., those followed by an atom) first
transfer the left argument to the auxiliary `U` register (held in the
DE register pair in the Z80 implementation).

### Addition

| **Unforth**          | `+ atom                                  ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V += U;                ` |
| **Z80**              | `ex DE, HL : atom : add HL, DE           ` |

### Subtraction

| **Unforth**          | `- atom                                  ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V = U - V;             ` |
| **Z80**              | `ex DE, HL : atom : ex DE, HL : xor A : sbc HL, DE` |

### Increment by 1

| **Unforth**          | `+1                                      ` |
| :--- | :--- |
| **C**                | `V++;                                    ` |
| **Z80**              | `inc HL                                  ` |

### Increment by 2

| **Unforth**          | `+2                                      ` |
| :--- | :--- |
| **C**                | `V += 2;                                 ` |
| **Z80**              | `inc HL : inc HL                         ` |

### Decrement by 1

| **Unforth**          | `-1                                      ` |
| :--- | :--- |
| **C**                | `V--;                                    ` |
| **Z80**              | `dec HL                                  ` |

### Decrement by 2

| **Unforth**          | `-2                                      ` |
| :--- | :--- |
| **C**                | `V -= 2;                                 ` |
| **Z80**              | `dec HL : dec HL                         ` |

### Double

| **Unforth**          | `*2                                      ` |
| :--- | :--- |
| **C**                | `V *= 2;                                 ` |
| **Z80**              | `add HL, HL                              ` |

### Halve

| **Unforth**          | `/2                                      ` |
| :--- | :--- |
| **C**                | `V /= 2;                                 ` |
| **Z80**              | `sra H : rr L                            ` |

### Negation

| **Unforth**          | `~                                       ` |
| :--- | :--- |
| **C**                | `V = -V;                                 ` |
| **Z80**              | `xor A : sub L : ld L, A : sbc A, A : sub A, H : ld H, A` |

### Multiplication
Complex operations are implemented in a runtime library.

| **Unforth**          | `* atom                                  ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V *= U;                ` |
| **Z80**              | `ex DE, HL : atom : call __RT_Mul        ` |

### Division

| **Unforth**          | `/ atom                                  ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V = U / V;             ` |
| **Z80**              | `ex DE, HL : atom : call __RT_Div        ` |

### Logical NOT

| **Unforth**          | `!                                       ` |
| :--- | :--- |
| **C**                | `V = !V;                                 ` |

### Bitwise OR

| **Unforth**          | `|| atom                                 ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V |= U;                ` |
| **Z80**              | `ex DE, HL : atom : ld A, L : or E : ld L, E : ld A, H : or D : ld H, A` |

### Bitwise AND

| **Unforth**          | `&& atom                                 ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V &= U;                ` |
| **Z80**              | `ex DE, HL : atom : ld A, L : and E : ld L, E : ld A, H : and D : ld H, A` |

### Bitwise OR

| **Unforth**          | `^^ atom                                 ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V ^= U;                ` |
| **Z80**              | `ex DE, HL : atom : ld A, L : xor E : ld L, E : ld A, H : xor D : ld H, A` |

### Biwise complement

| **Unforth**          | `cpl                                     ` |
| :--- | :--- |
| **C**                | `V = ~V;                                 ` |
| **Z80**              | `ld A, L : cpl : ld L, A : ld A, H : cpl : ld H, A` |

### Left shift

| **Unforth**          | `<<                                      ` |
| :--- | :--- |
| **C**                | `V = V << 1;                             ` |
| **Z80**              | `add HL, HL                              ` |

### Left shift circular

| **Unforth**          | `<<o                                     ` |
| :--- | :--- |
| **C**                | `V = (V << 1) | (V >> 15);               ` |
| **Z80**              | `ld A, H : rlca : adc HL, HL             ` |

### Right shift

| **Unforth**          | `>>                                      ` |
| :--- | :--- |
| **C**                | `V = V >> 1;                             ` |
| **Z80**              | `srl H : rr L                            ` |

### Right shift circular

| **Unforth**          | `>>o                                     ` |
| :--- | :--- |
| **C**                | `V = (V << 15) | (V >> 1);               ` |
| **Z80**              | `ld A, L : rrca : rr H : rr L            ` |

### Dereference

| **Unforth**          | `@                                       ` |
| :--- | :--- |
| **C**                | `V = *V;                                 ` |
| **Z80**              | `ld A, (HL) : inc HL : ld H, (HL) : ld L, A` |

### Dereference byte

| **Unforth**          | `@.                                      ` |
| :--- | :--- |
| **C**                | `V = *((char *)V);                       ` |
| **Z80**              | `ld L, (HL)                              ` |
|                      | `ld H, 0                                 ` |

### Field offset
Structures are referenced via pointers.
Fields of those structures are referenced indirectly.

| **Unforth**          | `. atom                                  ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; V = U + 2 * V;         ` |
| **Z80**              | `ex DE, HL : atom : add HL, HL : add HL, DE` |

### Field update
Note that the update advances the target address in `V` to the next field.

| **Unforth**          | `<- atom                                 ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; *U = V; V = U++;       ` |
| **Z80**              | `ex DE, HL : atom : ex DE, HL : ld (HL), E : inc HL : ld (HL), D : inc HL` |

### Poke a byte
Note that the update advances the target address in `V` to the next byte.

| **Unforth**          | `<-. atom                                ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; *((char *) U) = V & 0xff; V = U + 1;` |
| **Z80**              | `ex DE, HL : atom : ex DE, HL : ld (HL), E : inc HL` |

### Memory copy (ascending)
Memory copy a number of bytes in ascending address order.
Expected use is `source , count , dest ldir`.

| **Unforth**          | `...source... , ...count... , ...dest... ldir` |
| :--- | :--- |
| **C**                | `{ char *dst = V; int n = *SP++; char *src = *SP++; while (n) *dst++ = *src++; U = src; V = dst; }` |
| **Z80**              | `ex DE, HL : pop BC : pop HL : ldir      ` |

### Memory copy (descending)
Memory copy a number of bytes in descending address order.
Expected use is `source , count , dest lddr`.

| **Unforth**          | `...source... , ...count... , ...dest... lddr` |
| :--- | :--- |
| **C**                | `{ char *dst = V; int n = *SP++; char *src = *SP++; while (n) *dst-- = *src--; U = src; V = dst; }` |
| **Z80**              | `ex DE, HL : pop BC : pop HL : lddr      ` |

### Read from IO port
Read from the IO port number in the low byte of `V`.
The data read is written to `V`.

| **Unforth**          | `inp                                     ` |
| :--- | :--- |
| **C**                | `V = __read_io_port(V & 0xff);           ` |
| **Z80**              | `ld C, L                                 ` |
|                      | `in L, (C)                               ` |
|                      | `ld H, 0                                 ` |

### Write to IO port
Write the low byte of `V` to the IO port number in the low byte of `U`.

| **Unforth**          | `outp atom                               ` |
| :--- | :--- |
| **C**                | `U = V; V = atom; __write_io_port(U & 0xff, V & 0xff);` |
| **Z80**              | `ld C, E                                 ` |
|                      | `out (C), L                              ` |

### Heap allocation
A simple allocation-only heap is provided.
The heap pointer starts at the end of the generated object code and variables.
No bounds checking is implemented.

| **Unforth**          | `...count... alloc                       ` |
| :--- | :--- |
| **C**                | `U = HEAP; V += U; HEAP = V; V = U;      ` |
| **Z80**              | `ld DE, (HEAP) : add HL, DE : ld (HEAP), HL : ex DE, HL` |

### Indirect call
Call the procedure in `V` (if the procedure takes arguments, they must be passed 
on the stack).

| **Unforth**          | `...addr... call                         ` |
| :--- | :--- |
| **C**                | `(*V)();                                 ` |
| **Z80**              | `jp (HL)                                 ` |



## More Examples

(Some of these are ZX Spectrum centric.)

### Filling a byte range.

    \ src , n , x fill. {
        src <- x
        src , n + 1 , src + 1 ldir
    }

### Clearing the display attributes

    ; Clear the display by writing the same ink and paper colours
    ; to the entire attribute file.

    \ attr cls {
        ; We want to set the attribute ink and paper to be the same.
        ; attr = (attr & 0xf8) | ((attr >> 3) & 0x07)
        && #f8 -> attr
        >> >> >> & #07 || attr -> attr
        ; Fill the attributes.
        #5800 , $2ff , attr fill.
    }

### Eratosthenes' Sieve

    ; Calculate the primes up to 100 using Eratosthenes' Sieve.
    100 -> n
    n bytes -> sieve ; Allocate one byte for each number from 0..9999.
    ; Set the array
    sieve <-. 1
    sieve , n - 1 , sieve + 1 ldir
    ; Mark 0 and 1 as composite.
    sieve + 0 <-. 0
    sieve + 1 <-. 0
    ; Now we run the sieve.
    1 -> i
    : iloop
        i + 1 -> i
        i - n ifz done
        sieve + i @. ifz iloop ; Skip this if it is composite.
        ; We have a prime!  Clear its multiples.
        i * i -> j
        : jloop
            n - j iflt iloop
            sieve + j <-. 0
            j + i -> j
            jloop
    : done
    
## Possible Extensions

- inline machine code.
- named constants.








