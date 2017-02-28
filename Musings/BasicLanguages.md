# Basic Languages on the Z80

These are some musings on the topic of how to implement Basic-like languages on the Z80, specifically the ZX Spectrum.  Sinclair Basic was comfortable enough to program in, but ran like a concrete rabbit.  BBC Basic, on the other hand, was much quicker.  My career took a decade long detour into programming language design and implementation, so I understand now why the Spectrum Basic implementation was so slow.  What I don't really understand was why Basic implementers didn't go straight to compilation or, at the very least, some half-decent P-code style scheme.  But they didn't.  I'd like to point out here that the Z80 is an interesting compilation target in that it is seemingly designed to thwart any attempt at efficient language implementation.  But my first computers were a ZX-81 and a ZX Spectrum and those things ran on Z80s and that's what I learned.  Here are my thoughts on the matter.

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

* Built-in statements, such as `print 

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
