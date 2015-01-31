; This is where we parse and compile the program.
;
; We deal with scope by pushing any needed data followed by a
; handler address on the stack.  The a register
; is assigned the reason for a scope being closed so the scope
; handler can decide what to do.

ResetProg       call ResetHeap
                call ResetScan
                call ResetGen
                call ResetSymTabs
                ld hl, pEndProg
                push hl
                ret

Prog            call Scan
                cp TokNewID
                jp z, pNewID
                cp TokID
                jp z, pID
                cp TokEOF
                jp z, pEnd

                halt ; Prog syntax error!

pEnd            pop hl
                jp (hl)

pEndProg        cp TokEOF
                jp nz, pEndProgError
                ret

pEndProgError   halt ; Unexpected EOF.

pNewID          ld (newEntryPtr), hl    ; This is a new assignment or a new call.
                ld hl, (ScannedIDStart)
                ld (newIDStart), hl

                call Scan
                cp '='
                jp z, pNewAssgt
                ; cp '('
                ; jp z, pNewCall
                halt ; Expected '=' in new var assignment or '(' in fwd call.

pNewAssgt       call Expr
                ld (newVarType), a

                ld hl, newVarCode
                ld bc, newVarLength
                call Gen
                dec de
                dec de
                ld (newVarPtr), de

                ld (varAssgtCode + 1), de
                ld hl, varAssgtCode
                ld bc, varAssgtLength
                call Gen

                ld hl, (newEntryPtr)
                ld bc, (newIDStart)
                ld a, (newVarType)
                ld de, (newVarPtr)
                call AddEntry

                jp Prog

; We generate space for variables in-line in the program code,
; adding a jump around the data.  This has two advantages:
; (1) it simplifies the compiler and (2) it keeps the entire
; program in one place which can be followed by the stack and
; heap (otherwise we'd have to put the vars somewhere else, say
; growing down from some upper limit, with stack and heap in
; the middle.  Ugh.  The cost, of course, is 12 Ts every time
; we pass over this bit of code - a mere bagatelle!
;
newVarCode      jr newVarCodeEnd
                dw 0                    ; GC chain for heap vars.
                db 0                    ; Var type.
                dw 0                    ; Var value.
newVarCodeEnd   nop
newVarLength    equ newVarCodeEnd - newVarCode

varAssgtCode    ld (0), hl
varAssgtLength  equ * - varAssgtCode

pID             ld a, (hl)
                cp TypeInt
                jp z, pAssgt
                cp TypeInts
                jp z, pAssgt
                cp TypeStr
                jp z, pAssgt
                cp TypeStrs
                jp z, pAssgt
                cp TokIf
                jp z, pIf
                cp TokElif
                jp z, pElif
                cp TokElse
                jp z, pElse
                cp TokEnd
                jp z, pEnd
                halt                    ; Unknown keyword!

pAssgt          push hl                 ; Save the assignment target details.
                call Scan
                cp '='
                jp nz, pExpectedEq
                call Expr
                pop hl                  ; Restore the assignment target details.
                cp (hl)                 ; Check the types match.
                jp nz, pAssgtTypeError
                inc hl
                ld e, (hl)
                inc hl
                ld d, (hl)
                ld (varAssgtCode + 1), de
                ld hl, varAssgtCode
                ld bc, varAssgtLength
                call Gen
                jp Prog

pExpectedEq     halt                    ; Expected an assignment.

pAssgtTypeError halt

pIf             call Expr
                cp TypeInt
                jp nz, pIfCondTypeError
                ld hl, ifCode
                ld bc, ifLength
                call Gen
                dec de
                dec de                  ; de = ptr to if false jp tgt.
                push de
                ld de, pCloseIf
                push de
                jp Prog

pIfCondTypeError halt

ifCode          ld a, h
                or l
                jp z, 0
ifLength        equ * - ifCode

pCloseIf        cp TokEnd
                jp nz, pUnclosedIf
                ld de, (CodePtr)
                pop hl                  ; hl = ptr to if false jp tgt.
                ld (hl), e
                inc hl
                ld (hl), d
                jp Prog

pUnclosedIf     halt

pElif           halt
pElse           halt

