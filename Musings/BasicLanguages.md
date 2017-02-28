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
* It's a little-endian architecture.

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
* `OP` stands for the application of any built-in operator.

Later on I intend to introduce `CALL` and `RET` instructions when exploring how user-defined functions might be supported.

## Interpreting tokens or Token Threaded Code

TTC is a Forth-ism where each simple-form instruction must be examined to decide how it should be handled.  In this case, we might reasonably assume there are only a modest number of such which could be handled via a jump table.  In this case we might choose 
