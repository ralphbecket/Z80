; A token is one of the following:
; - EOF indicated by a 0 byte;
; - a left or right parenthesis;
; - an unsigned integer;
; - an identifier, starting with a letter or underscore, followed by alphanumerics;
; - an identifier comprised of non-alphanumeric characters.
; Whitespace is simply skipped.

; --
; A: (TokKind)
; DE: (CurrSrcPtr)
; HL: (TokValue) if A = TokNum, (TokLen) if A = TokId.
NextToken               ld de, (CurrSrcPtr)

ntSkipSpace             ld a, (de)
                        call ClassifyChar
                        ld a, c
                        cp ccIsSpace
                        inc de
                        jr z ntSkipSpace

ntNonSpace              dec de
                        ld (TokStart), de
                        cp ccIsAlpha
                        jr z, ntAlphaNumId
                        cp ccIsDigit
                        jr z, ntNum
                        cp ccIsSym
                        jr z, ntSymId
                        cp ccIsPar
                        jr z, ntPar

ntEof                   ld a, TokIsEof
                        ld (TokKind), a
                        ret

ntAlphaNumId            equ *
ntAlphaNumIdLoop        inc de
                        ld a, (de)
                        call ClassifyChar
                        ld a, c
                        and ccIsAlpha + ccIsDigit
                        jr nz, ntAlphaNumIdLoop

ntIdEnd                 ld (CurrSrcPtr), de
                        ld hl, (TokStart)
                        ex de, hl
                        sbc hl, de
                        ld (TokLen), hl
                        ld a, TokIsId
                        ld (TokKind), a
                        ret

ntSymId                 equ *
ntSymIdLoop             inc de
                        ld a, (de)
                        call ClassifyChar
                        ld a, c
                        and ccIsSym
                        jr nz, ntSymIdLoop
ntSymIdEnd              jr ntIdEnd

ntPar                   inc de
                        jr ntIdEnd

ntNum                   dec de
                        ld a, (de)
                        sub a, '0'
                        ld h, 0
                        ld l, a
                        push hl
ntNumLoop               inc de
                        ld a, (de)
                        call ClassifyChar
                        ld a, c
                        cp ccIsDigit
                        jr nz, ntNumEnd
                        pop hl
                        add hl, hl              ; Calculate HL = 10 * HL + Digit.
                        ld a, (de)
                        sub a, '0'
                        add a, l
                        ld c, a
                        ld a, h
                        adc a, 0
                        ld b, a
                        add hl, hl
                        add hl, hl
                        add hl, bc
                        push hl
                        jr ntNumLoop
ntNumEnd                ld (CurrSrcPtr), de
                        pop hl
                        ld a, TokIsNum
                        ld (TokKind), a
                        ret

TokIsEof                equ 0
TokIsNum                equ 1
TokIsId                 equ 2   ; This includes symbol tokens and parentheses.

CurrSrcPtr              dw 0    ; Pointer to current char in source code.
; Data regarding token just read.
TokStart                dw 0    ; Ptr to first char in id token.
TokLen                  dw 0    ; Token length.
TokValue                dw 0    ; Value of num token.
TokKind                 db 0

; A: char.
; --
; A: char.
; C: char classification.
; HL: scratched.
ClassifyChar            ld hl, ccTable
                        ld b, ccTableEntries
ccLoop                  ld c, (hl)
                        inc hl
                        cp (hl)
                        inc hl
                        jr c, ccMiss
                        cp (hl)
                        ret c
ccMiss                  inc hl
                        djnz ccLoop
                        ld c, ccIsSym
                        ret

ccIsEof                 equ 0
ccIsPar                 equ 1
ccIsDigit               equ 2
ccIsAlpha               equ 4
ccIsSym                 equ 8
ccIsSpace               equ 16

; This table is ordered to try and succeed quickly.
; Any character not matched here is ccIsSym.
ccTable                 db ccIsSpace, 1, ' '+1
                        db ccIsAlpha, 'a', 'z'+1
                        db ccIsDigit, '0', '9'+1
                        db ccIsPar, '(', ')'+1
                        db ccIsAlpha, 'A', 'Z'+1
                        db ccIsAlpha, '_', '_'+1        ; This is standard.
                        db ccIsEof, 0, 0+1
ccTableEntries          equ (* - ccTable) / 3

