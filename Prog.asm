; This is where we parse and compile the program.

ResetProg       call ResetHeap
                call ResetScan
                call ResetGen
                call ResetSymTabs
                ret

Prog            proc

                call Scan
                cp TokEOF
                ret z
                cp TokNewID
                jp z, newAssgtOrCall

                halt ; Prog syntax error!

newAssgtOrCall  ld (newEntryPtr), hl    ; We just read a TokNewID.
                ld hl, (ScannedIDStart)
                ld (newIDStart), hl

                call Scan
                cp '='
                jp z, newAssgt
                ; cp '('
                ; jp z, fwdCall
                halt ; Expected '=' in new var assignment or '(' in fwd call.

newAssgt        call Expr
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

                call Alloc              ; hl = new entry.

                ld de, (newEntryPtr)    ; Set up the sym tab pointer to the new entry.
                ex de, hl
                ld (hl), e
                inc hl
                ld (hl), d
                ex de, hl

                ld de, (newIDStart)     ; Set the name field of the var entry.
                ld (hl), e
                inc hl
                ld (hl), d
                inc hl

                ld a, (newVarType)      ; Set the type field of the var entry.
                ld (hl), a
                inc hl

                ld de, (newVarPtr)      ; Set the addr field of the var entry.
                ld (hl), e
                inc hl
                ld (hl), d
                inc hl

                xor a                   ; Set the next entry field to 0.
                ld (hl), a
                inc hl
                ld (hl), a

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

varAssgtCode ld (0), hl
varAssgtLength equ * - varAssgtCode

newEntryPtr     dw 0
newIDStart      dw 0
newIDEnd        dw 0
newVarPtr       dw 0
newVarType      db 0

                endp
