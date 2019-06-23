; The grammar divides symbols into five kinds: values (constants and variables),
; prefix, postfix, and infix operators, and special cases.
;
; Essentially, a program follows the following structure:
;
;       Expr ::= Prefix* Value Postfix* [Infix Expr]
;

DoExpr                  ld hl, (StateAndContext)
                        push hl
                        ld hl, CloseExpr
                        push hl
                        ld a, CloseExprPrec
                        push af
                        jp GoToAtPrefixOp

DoNextSym               call NextToken
DoCurrSym               ld a, (TokKind)

                        cp TokIsEof
                        jp z, DoEof

                        cp TokIsNum
                        jp z, DoNum

                        call FindSym
                        jp nz, DoSymCode

DoNewSym                halt                    ; XXX Fill this in!

DoEof                   halt                    ; XXX Fill this in!

DoSymCode               jp (hl)

; ---- Prefix ops. ----

; HL: prefix op generator code ptr.
; --
DoPrefixOp              ld a, (State)
                        cp AtValue
                        jp z, DoCloseExpr
                        cp AtPrefixOp
                        jp z, _DoPrefixOp
                        jp Error

_DoPrefixOp             push hl                 ; Push code generator.
                        jp DoNextSym

GoToAtValue             ld a, AtValue
                        ld (State), a
                        jp DoNextSym

; ---- Constants ----

DoNum                   ld a, (State)
                        cp AtValue
                        jp z, DoCloseExpr
                        cp AtPrefixOp
                        jp z, _DoNum
                        jp Error

_DoNum                  ld hl, (TokValue)
                        GenLdHLConst()
                        ret                     ; Now compile prefix ops.

; ---- Variables ----

; ---- Postfix ops. ----

DoPostfixOp             ld a, (State)
                        cp AtValue
                        jp z, _DoPostfixOp
                        jp Error

_DoPostfixOp            ld de, DoNextSym
                        push de
                        jp (hl)

; ---- Infix ops. ----

; HL: infix op code generator ptr.
; A: operator precedence (higher binds more tightly).
; --
DoInfixOp               ld (InfixOpCodePtr), hl
                        ld (InfixOpPrec), a
                        ld a, (State)
                        cp AtValue
                        jp z, _DoInfixOp
                        jp Error

_DoInfixOp              ld a, (InfixOpPrec)
                        ld b, a                 ; B: curr infix op prec.
                        pop af                  ; A: prev infix op prec.
                        cp b
                        jp c, dioPushInfixOp

dioGenPrevInfixOp       ld hl, _DoInfixOp
                        ex (sp), hl             ; HL: prev infix code gen ptr.
                        jp (hl)

dioPushInfixOp          push af                 ; Prev infix op prec.
                        ld hl, (InfixOpCodePtr)
                        push hl                 ; Curr infix code gen ptr.
                        push bc                 ; Curr infix op prec.

GoToAtPrefixOp          ld hl, GoToAtValue
                        push hl
                        ld a, AtPrefixOp
                        ld (State), a
                        jp DoNextSym

; ---- Parentheses. ----

; LPar is treated as an infix operator with the second-lowest precedence.
; RPar is treated as an infix operator with the lowest precedence.
; An LPar cancels the matching RPar.

DoLPar                  ld a, (State)
                        cp AtPrefixOp
                        jp z, _DoLPar
                        jp DoCloseExpr          ; This isn't part of this expr.

_DoLPar                 ld hl, MatchRPar
                        push hl
                        ld a, LParPrec          ; This is the second-lowest precedence.
                        push af
                        jp DoNextSym

MatchRPar               ld a, (State)
                        cp AtRPar
                        jp nz, Error
                        ld a, AtValue
                        ld (State), a
                        ret                     ; Generate any stacked prefix operators.

DoRPar                  ld a, (State)
                        cp AtValue
                        jp z, _DoRPar
                        cp AtPrefixOp
                        jp z, Error
                        jp DoCloseExpr

_DoRPar                 ld a, AtRPar
                        ld (State), a
                        ld a, RParPrec          ; This is the lowest precedence.
                        ld (InfixOpPrec), a
                        jp _DoInfixOp           ; Generate any stacked infix operators.

; ---- Closing the expr. ----

DoCloseExpr             ld a, CloseExprPrec
                        ld (InfixOpPrec), a
                        jp _DoInfixOp           ; Generate any stacked infix operators.

CloseExpr               pop hl
                        ld (StateAndContext), hl
                        ; XXX Also need to tell the tokeniser to replay the last token.
                        ret

; ---- Error reporting. ----

Error                   halt                    ; XXX Fill this in!

; ---- Compiler states. ----

AtPrefixOp              equ 1
AtValue                 equ 2
AtRPar                  equ 3
AtExprEnd               equ 4

CloseExprPrec           equ 0
RParPrec                equ 1
LParPrec                equ 2

StateAndContext         equ *
Context                 db 0                    ; NYI
State                   db 0

InfixOpPrec             db 0
InfixOpCodePtr          dw 0

