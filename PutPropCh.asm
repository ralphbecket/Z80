


; PutPropCh(a = char)
;
; Print a character using a proportionally spaced font
; wherein each character is defined as [row0 + width][row1]...[row7]
; (width must be in 0..7 corresponding to 1..8 pixels, row0
; implicitly has its last three bits blank).
; Unlike some other schemes, this routine applies colour attributes
; and uses masking, rather than or/xor.
;
PutPropCh       proc

                ; XXX Handle NL, non-printing chars, etc.
                sub 32

                ld h, 0             ; Calc the char data addr.
                ld l, a
                add hl, hl
                add hl, hl
                add hl, hl
                ld de, (PropCharSet)
                add hl, de          ; hl = ptr to [row0 + width][row1]...[row7].
                ld a, (hl)
                and $07
                inc a
                ;inc a
                ld b, a             ; a, b = ch width in px.
                push hl
                pop ix              ; ix = ptr to [row0 + width][row1]...[row7].

checkSpace      ld hl, PutPropX
                add a, (hl)
                ld (hl), a          ; Update PutPropX for next ch.
                jr nc, calcShift

                push bc             ; Drat!  We do need a NL.
                push ix
                call PutNL          ; This should zero PutPropX.
                pop ix
                pop bc
                ld a, b
                jr checkSpace       ; Let's try again!

calcShift       sub b
                cpl
                and $07
                inc a               ; a = # px to shift left (always +ve).
                cp b
                ld b, a             ; b = # px to shift left (always +ve).
                ld a, 0
                adc a, a
                ld c, a             ; c = if span two cols then 1 else 0.

calcMask        ld a, $ff
                push bc
calcMaskLp      add a, a
                djnz calcMaskLp     ; a = bitmap drawing mask.
                pop bc
                ld (drawMask + 1), a; SMC!

drawAttrs       ld hl, (PutAttrPtr)
                ld a, (PutAttr)
                ld (hl), a          ; Fill in the left attr.

                bit 0, c
                jr z, calcDispPtr
                inc hl              ; Fill in right attr.
                ld (hl), a
                ld (PutAttrPtr), hl
                dec hl

calcDispPtr     ld a, h             ; Convert hl from attr ptr to disp ptr.
                and $03
                add a, a
                add a, a
                add a, a
                or $40
                ld h, a
                ex de, hl           ; de = disp ptr.

                ld h, 0             ; Load the first row bitmap.
                ld a, (ix+0)
                and $f8             ; Low three bits are width data.
                ld l, a

drawBitmap      push bc
shiftBitmap     add hl, hl
                djnz shiftBitmap
                pop bc              ; hl = shifted row bitmap.

                ld a, (de)
drawMask        and 0               ; SMC!
                or h
                ld (de), a          ; Fill in the left byte.
                bit 0, c
                jr z, prepNextRow

                inc e               ; Fill in the right byte.
                ld a, l
                ld (de), a
                dec e

prepNextRow     inc ix
                ld h, 0
                ld l, (ix+0)
                inc d
                ld a, d
                and $07
                jr nz, drawBitmap

                ld a, (PutPropX)        ; Handle some edge cases.
                and a
                jr nz, notAtRowEnd

                dec a                   ; Ensure we do a NL on next char.
                ld (PutPropX), a
                ret

notAtRowEnd     and $07
                ret nz

                ld hl, PutAttrPtr       ; Move on to the next display cell.
                inc (hl)
                ret

                endp

PropCharSet     dw PropChars
PutPropX        db 0
PutAttrPtr      dw $5800
PutAttr         db %01111000
PutNL           ret

                include "PropChars.asm"

