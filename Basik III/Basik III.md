# Basik III

Ralph Becket, 2019

## Introduction

This is my third run-up to writing a quasi-decent compiler for a BASIC-like language for the venerable ZX Spectrum (circa 1982, 3.5 MHz Z80A CPU, 48 KBytes RAM, 16 KBytes ROM).  The BASIK interpreter on the Speccy's ROM was pretty slow and it has always seemed to me that it should have been possible to provide
* a better language (BASIC wasn't exactly standardised in the home computer market)
* that was compiled (interpretation incurs substantial overheads)
* and was strongly typed (to avoid the costs of dynamic dispatch)
* and had proper procedures and functions (BASIC programs of the day were piles of spaghetti).

The generated code should be at least an order of magnitude faster than the BASIC interpreter, aiming for around 30% of the performance of hand-written assembly code.  The compiler itself should be small (one or two KBytes) and quick (compiling, say, 100 lines per second).

The previous iterations of my ideas have had various flavours.  Some abandoned functions and procedures.  Some assumed the majority of data would be 16-bit integers (this makes sense for games programming).  Some looked at code density using byte-coding optimised for execution speed.

My current thoughts are that for the exercise to be meaningful, we have to have functions and procedures, and we cannot assume that all or even most data would be 16-bit quantities.  However, I am, for speed, prepared to forgo recursion: very few BASIC programmers of that era were aware of the concept, let alone comfortable with it (well, I can only think of one BASIC implementation of the day that even supported proper functions: the excellent BBC BASIC).

## Basics (ho ho)

All variables and function parameters will be statically typed (byte, int, float, string, and arrays thereof) and statically allocated (i.e., have a fixed address in memory).

All functions and procedures must be defined before they are used.  Recursion is not supported (it is quite expensive to support on the Z80 and very few programmers of the day would actually use the facility).

Scope: a variable and function can only be referred to iff it is defined earlier and is not local to a previously defined function.

All variables and constants are passed via pointers to their values, with the exception of byte and int quantities which are passed by value.

Expressions are evaluated on the stack.  Operators and functions pop arguments from the stack and push the result on to the stack.

There will be no line numbers or labels and no `goto` statement.  All control flow is structured via `if-elif-else-end` and `while-continue-break-end` structures (we might reasonably consider adding a `for-end` loop) and function/procedure calls.

## Source code, tokenisation, the symbol table, parsing and compiling.



The compiler will be 
