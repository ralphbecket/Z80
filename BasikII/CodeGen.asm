; Code generation for Basik II.
;
; The code generation pointer (i.e., where the next byte of
; generated code will go) is kept in IX.
;
; Code generation is largely via macros because otherwise it's
; too horrible to contemplate.

Gen1            macro (x1)
                ld (ix), x1
                inc ix
                mend

Gen2            macro (x1, x2)
                ld (ix), x1
                inc ix
                ld (ix), x2
                inc ix
                mend

Gen3            macro (x1, x2, x3)
                ld (ix), x1
                inc ix
                ld (ix), x2
                inc ix
                ld (ix), x3
                inc ix
                mend

GenHL           macro ()
                Gen2(h, l)
                mend

Gen1HL          macro (x1)
                Gen1(x1)
                GenHL()
                mend

Gen2HL          macro (x1, x2)
                Gen2(x1, x2)
                GenHL()
                mend

Gen1Const       macro (x1, x2)
                Gen1(x1)
                Gen1(low x2)
                Gen2(high x2)
                endm

Gen2Const       macro (x1, x2, x3)
                Gen2(x1, x2)
                Gen1(low x3)
                Gen2(high x3)
                endm

GenLdHLConst    macro (x1)
                Gen1Const($21, x1)
                endm

GenLdHLVar      macro (x1)
                Gen1Const($2a, x1)
                endm

GenStHLVar      macro (x1)
                Gen1Const($22, x1)
                endm

GenLdDEConst    macro (x1)
                Gen1Const($11, x1)
                endm

GenLdDEVar      macro (x1)
                Gen2Const($ed, $5b, x1)
                endm

GenStDEVar      macro (x1)
                Gen2Const($ed, $53, x1)
                endm

GenLdBCConst    macro (x1)
                Gen1Const($01, x1)
                endm

GenLdBCVar      macro (x1)
                Gen2Const($ed, $4b, x1)
                endm

GenStBCVar      macro (x1)
                Gen2Const($ed, $43, x1)
                endm

GenCall         macro (x1)
                Gen1Const($cd, x1)
                endm

GenCallZ        macro (x1)
                Gen1Const($cc, x1)
                endm

GenCallNZ       macro (x1)
                Gen1Const($c4, x1)
                endm

GenRet          macro ()
                Gen1($c9)
                endm

GenJp           macro (x1)
                Gen1Const($c3, x1)
                endm

GenJpZ          macro (x1)
                Gen1Const($ca, x1)
                endm

GenJpNZ         macro (x1)
                Gen1Const($c2, x1)
                endm

GenJpHL         macro ()
                Gen1($e9)
                endm

GenExDEHL       macro ()
                Gen1($eb)
                endm

GenPushHL       macro ()
                Gen1($e5)
                endm

GenPopHL        macro ()
                Gen1($e1)
                endm

GenPushDE       macro ()
                Gen1($d5)
                endm

GenPopDE        macro ()
                Gen1($d1)
                endm

GenPushBC       macro ()
                Gen1($c5)
                endm

GenPopBC        macro ()
                Gen1($c1)
                endm

GenIfZ          macro (x1)
                jr z, Skip
                x1
Skip            equ *
                endm

GenIfNZ         macro (x1)
                jr nz, Skip
                x1
Skip            equ *
                endm

; Compiling expressions.
;
; This gets a little involved.  Forth gets away with being
; simple because
; - it uses RPN (ugh),
; - it accepts woeful relative performance,
; - it doesn't do any meaningful compile-time error checking.
;
; Instead, I'm going to adopt something slightly more
; conventional, at the cost of slightly greater complexity.
;
; The grammar for expressions in Basik II is this:
;       Expr  ::= Value [BinOp Expr]
;       Value ::= UnOp* (Const | Var | '(' Expr ')')
; and, at least to start with, all operators will have
; the same priority and nest to the left -- that is,
; x + y * z  will denote  (x + y) * z.  This can be
; rectified later, but for now I think it's something we
; can live with.
;
; Expressions are compiled by pushing operators on to the
; stack, then compiling them in LIFO order immediately after
; a const or var has been compiled (modulo special handling
; for the start and end of the expression and for parentheses).
;
; An example to illustrate the basic idea.  I will write
; [*] to denote a note to compile a * operator on the stack
; and [[*]] to denote the generated code for the * operator
; and 'u*' to denote the unary form of the * operator as
; opposed to '*', its binary form.
;
;       Expr tokens     | Stack         | Generated code
;
;       x + - y * z     |               |
;         + - y * z     |               | [[x]]
;           - y * z     | [+]           | [[x]]
;             y * z     | [+] [u-]      | [[x]]
;               * z     | [+] [u-]      | [[x]] [[y]]
;               * z     | [+]           | [[x]] [[y]] [[u-]]
;               * z     |               | [[x]] [[y]] [[u-]] [[+]]
;                 z     | [*]           | [[x]] [[y]] [[u-]] [[+]]
;                       | [*]           | [[x]] [[y]] [[u-]] [[+]] [[z]]
;                       |               | [[x]] [[y]] [[u-]] [[+]] [[z]] [[*]]
;
; To keep track of where we are in the grammar, we use a state machine.

eExpectingValue         equ 1
eExpectingBinOp         equ 2
eClosingPar             equ 3
ePoppingOps             equ 4
eClosingExpr            equ 5



Defer           macro (x1)              ; Push an addr on the stack.
                ld bc, x1
                push x1
                endm
