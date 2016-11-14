/*****************************************************************************

Basik II

I always thought the Basic interpreter on the ZX Spectrum was
terrible in the sense of being unneccessarily slow and bloated.
This is my second attempt to sketch out something better: a
fast, single-pass compiled language with functions.  My starting
point for the design was Forth, but Forth (a) maps really badly
on to the Z80 and (b) is unreadable and (c) is only short and cute
because it doesn't do any error checking.  It seems to me that we
should be able to take the spirit of Forth, but produce a fast
compiler for an imperative language with functions and structured
control flow and infix operators that maps down to efficient Z80
machine code.  Moreover, I want to do this in a way that could
have been done back in the day.

Since this is more of a programming and design exercise than
anything else, I'm going to call my language 'Basik' and it will
look something like this:

- variables will be 16-bit integers by default;
- support for strings, arrays, reals, etc. should be easy to add,
but without affecting the key 16-bit integer performance;
- you have to have functions, because without functions you have
nothing;
- you have to have structured control flow and not 'goto's because
we have learned some taste.

Efficient expressions and variables are at the heart of a speedy
compiled language.  The Z80 aggressively doesn't like multiple
stacks, stack frames (IX and IY, ho ho), or any of that stuff.
It's actually a pretty rotten architecture, now I think about it.
So, the fastest way to fetch and retrieve 16-bit data is from
fixed memory addresses.  Since woefully few people understand or
use recursion, and since it is so hard to support efficiently on
the Z80 (just look at any stack frame set-up/tear-down code from
a modern C compiler targetting the Z80... shudder), I will *not*
support recursion.  Hmm, maybe I should call this 'Fortran Lite'.

Okay, here are examples of the sort of code I expect to generate
(I'll use &x to denote the memory address of variable x).  I'm
trying to show what naive code generation might do, to illustrate
that the design decisions just described make many small optimisations
less meaningful when compared with the overheads of dual stack
manipulation (Forth) or random stack-frame access via IX/IY (with
recursion).  For expressions, I'll adopt the following rules:
the most recent result is always left in HL; for binary ops, the
left and right arguments will be passed in DE and HL respectively.

10 * x + y
----------
ld hl, 10
ex de, hl     ; This couplet could be peepholed into 'ld de, 10'.
ld hl, (&x)
call Mul      ; Result is left in HL
ex de, hl
ld hl, (&y)
add hl, de

Compare that to the amount of pushing, popping, and NEXTing that
would happen in Forth.  Ugh.

f 1 (x + 1) y ; No parentheses or commas, it's beautiful!
-------------
ld hl, 1
ld (&f_1), hl ; Function parameters have fixed addresses.
ld hl, (&x)
ex de, hl
ld hl, 1
add hl, de    ; The last three lines cry out for peepholing.
ld (&f_2), hl
ld hl, (&y)
ld (&f_3), hl
call f

if x = y then p else q end
--------------------------
ld hl, (&x)
ex de, hl
ld hl, (&y)
xor a
sbc hl, de    ; Sigh, Z80...
jp z, Else
ld hl, (&p)
jp End
Else:
ld hl, (&q)
End:

I can't come up with any scheme that is faster than this that
doesn't invoke the kind of compiler technology that would have
been infeasible to bootstrap on a ZX Spectrum.

*****************************************************************************/

                        zeusemulate "48k", "ula+"
Zeus_PC                 equ Main
Zeus_SP                 equ $0000
                        org $8000

Main                    halt

                        include "Tokeniser.asm"
                        include "SymTab.asm"
                        include "CodeGen.asm"
                        include "Compiler.asm"
                        include "Operators.asm"

                        zeusprint * - Main, "bytes"








