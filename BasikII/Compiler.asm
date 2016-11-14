


; ---- Compiler state transitions. ----
;
; The grammar divides symbols into five kinds: values (constants and variables),
; prefix, postfix, and infix operators, and special cases.
;
; Essentially, a program follows the following structure:
;
;       Expr ::= Prefix* Value Postfix* [Infix Expr]
;
;

; Symbol kinds.
SymIsPrefix             equ 0
SymIsValue              equ 3
SymIsPostfix            equ 6
SymIsInfix              equ 9
SymIsSpecial            equ 12

ProcessNextSym          call NextToken
                        cp TokIsEof
                        jr z, pnsEof
                        cp TokIsNum
                        jr z, pnsNum
                        call FindSym
                        jr nz, pnsSym

pnsNewSym               halt                    ; XXX Fill this in!

pnsEof                  halt                    ; XXX Fill this in!

pnsNum                  ld a, SymIsValue
                        ld (SymKind), a
                        jr ProcessSym

pnsSym                  ld a, (hl)              ; Every symbol table entry starts with
                        inc hl                  ; the symbol's kind (one byte) and
                        ld (SymKind), a         ; the symbol's code ptr (two bytes).
                        ld (SymDataPtr), hl

ProcessSym              ld a, (SymKind)         ; Jump to (State) + (SymKind).
                        ld e, a
                        ld d, 0
                        ld hl, (State)
                        add hl, de
                        jp (hl)

; This macro fetches the data pointed to by the SymDataPtr.

LdHLSymData             macro ()
                        ld hl, (SymDataPtr)
                        ld a, (hl)
                        inc hl
                        ld h, (hl)
                        ld l, a
                        endm

; ---- Prefix operators. ----
;
; The code generator addresses of prefix operators are pushed
; on to the stack.  The bottom "operator" is a pseudo-op which
; simply moves the expression parser state to AtValue.
;
; Prefix operator code generators must end with EndPrefixOp().

GoToAtPrefix            ld hl, EndPrefixGen
                        push hl
                        ld hl, AtPrefix
                        ld (State), hl
                        jr ProcessNextSym

EndPrefixGen            equ GoToAtValue

AddPrefixOp             LdHLSymData()           ; We must be AtPrefix here.
                        push hl                 ; Prefix op generators must
                        jr ProcessNextSym       ; end with EndPrefixOp().

GoToAtValue             ld hl, AtValue
                        ld (State), hl
                        jr ProcessNextSym

EndPrefixOp             macro ()
                        ret
                        endm

; ---- Values. ----
;
; Values are constants and variables.  Function calls
; are handled by 'special' code which is executed
; immediately.  Function call generators must end with
; EndValue().

GenValue                ld a, (TokKind)
                        cp TokIsNum
                        jr nz, GenVar

GenConst                ld hl, (TokValue)
                        GenLdHLConst()
                        EndValue()

GenVar                  LdHLSymData()
                        GenLdHLVar()
                        EndValue()

EndValue                macro ()
                        ret                     ; Start compiling prefix ops.
                        endm

; ---- Postfix operators. ----
;
; Postfix operators are invoked directly as special cases.
;
; Postfix operator code generators must end with EndPostfixOp().

GenPostfixOp            equ RunSpecialCaseCode

EndPostfixOp            macro ()
                        jp ProcessNextSym
                        endm

; ---- Infix operators. ----
;
; Infix operators are stacked, code generator address first, then
; precedence number.  Higher precedence means tighter binding.
; Equal precedence means "associate to the left" (i.e., there are no
; right-associative operators).
;
; Infix operators must end with EndInfixOp().

EndInfixOp              macro ()
                        jp AddInfixOp
                        endm

AddInfixOp              ld a, (NewOpPrecedence)
                        pop bc                  ; C is prev. op. precedence.
                        cp c
                        ret z
                        ret c                   ; Compile prev. op. if new precedence is not higher.
                        push bc                 ; Restore prev. op. precedence.
                        ld c, a
                        ld hl, (NewOpCodeGenPtr)
                        push hl
                        push bc                 ; Push new op code gen ptr. and precedence.
                        ld hl, AtInfix
                        ld (State), hl
                        jp ProcessNextSym

; ---- Special-case code. ----
;
; Special cases are executed directly and are expected to do their
; own error checking, generation, and state transitions.

RunSpecialCaseCode      LdHLSymData()
                        jp (hl)

; ---- Error states. ----

UnexpectedPostfixOp     halt

UnexpectedInfixOp       halt

; ---- State transition jump tables. ----

AtPrefix                jp AddPrefixOp
                        jp GenValue
                        jp UnexpectedPostfixOp
                        jp UnexpectedInfixOp
                        jp RunSpecialCaseCode

AtValue                 jp atvalCloseExpr       ; This prefix op can't be part of this expr.
                        jp atvalCloseExpr       ; This value can't be part of this expr.
                        jp GenPostfixOp
                        jp AddInfixOp
                        jp RunSpecialCaseCode

AtPostfix               equ AtValue             ; This has the same transition table.

AtInfix                 jp atinfAddPrefixOp
                        jp atinfGenValue
                        jp UnexpectedPostfixOp
                        jp UnexpectedInfixOp
                        jp RunSpecialCaseCode

State                   dw AtPrefix             ; The current compiler state.
SymKind                 db 0
NewOpPrecedence         db 0
NewOpCodeGenPtr         dw 0

