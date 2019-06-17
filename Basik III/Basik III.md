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

## Sample Source Code

```
; Insertion sort.
proc IsortPass ints xs int i:
  this = xs[i]
  while 0 < i
    prev = xs[i - 1]
    if prev <= this
      break
    end
    xs[i] = prev
    i = i - 1
  end
  xs[i] = this
end
proc Isort ints xs:
  n = len xs
  i = 1
  while i < n
    IsortPass xs i
    i = i + 1
  end
end
a = NewInts 3
a[0] = 3
a[1] = 1
a[2] = 2
Isort a
```

And how the above might be compiled (recall that we want something _simple_ to generate -- obviously hand written assember is going to be way tighter, but any kind of optimising compiler is going to be a _much_ bigger enterprise):
```
  jp _IsortPassEnd
IsortPass:
  pop DE                        ; Save return addr.
  pop HL : ld (&i_1), HL        ; Arg 2.
  pop HL : ld (&xs_1), HL       ; Arg 1.
  push DE                       ; Push return addr.
  ; this = xs[i]
  ld HL, &xs_1 : push HL        ; xs
  ld HL, &i_1 : push HL         ; i
  call IntsLD                   ; xs[i]
  pop HL : ld (&this_1), HL     ; this = xs[i]
  ; while 0 < i
_Loop1:
  ld HL, 0 : push HL            ; 0
  ld HL, (&i_1) : push HL       ; i
  call IntLT                    ; 0 < i
  pop HL
  ld A, H
  or L
  jp z, _Loop1End
  ; prev = xs[i - 1]
  ld HL, &xs_1 : push HL        ; xs
  ld HL, (&i_1) : push HL       ; i
  ld HL, 1 : push HL            ; 1
  call IntSub                   ; i - 1
  call IntsLD                   ; xs[i - 1]
  pop HL : ld (&prev_1), HL     ; prev = xs[i - 1]
  ; if prev <= this
_If1:
  ld HL, (&prev_1) : push HL    ; prev
  ld HL, (&this_1) : push HL    ; this
  call IntLE                    ; prev <= this
  pop HL
  ld A, H
  or L
  jp z, _If1End
  jp _Loop1End                  ; break
_If1End
  ; xs[i] = prev
  ld HL, &xs_1 : push HL        ; xs
  ld HL, (&i_1) : push HL       ; i
  ld HL, (&prev_1) : push HL    ; prev
  call IntsST                   ; xs[i] = prev
  ; i = i - 1
  ld HL, (&i_1) : push HL       ; i
  ld HL, 1 : push HL            ; 1
  call IntSub                   ; i - 1
  pop HL : ld (&i_1), HL        ; i = i - 1
  ; loop
  jp _Loop1
_Loop1End
  ; xs[i] = this
  ld HL, &xs_1 : push HL        ; xs
  ld HL, (&i_1) : push HL       ; i
  ld HL, (&this) : push HL      ; this
  call IntsST                   ; xs[i] = this
  ; end
  ret
_IsortPassEnd:
jp _IsortEnd
Isort:
  ...
_IsortEnd:
...
```

## Source code, tokenisation, the symbol table, parsing and compiling.



The compiler will be 
