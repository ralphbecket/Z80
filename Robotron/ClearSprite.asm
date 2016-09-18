; ClearSprite
;
; Clears a 12x12 px sprite on a 4px boundary.
;
; DE: yx for x in [0..61], y in [0..45]

ClearSprite             equ *

                        ; Calculate various SMC deltas.

                        ld hl, %0000000000001111 ; Left-image mask.
                        srl e
                        jr nc, CS_SetMask
                        ld hl, %1111000000000000 ; Right-image mask
CS_SetMask              ld (CS_Mask), hl
                        xor a
                        srl d
                        jr nc, CS_SetDispPtrDelta
                        ld a, 4
CS_SetDispPtrDelta      ld (CS_DispPtrDelta), a

                        ; Calculate the disp ptr.

                        ld a, d
                        rrca
                        rrca
                        rrca
                        and %11100000
                        or e
                        ld l, a
                        ld a, d
                        and %11111000
                        add a, $40
                        add a, 00
CS_DispPtrDelta         equ * - 1
                        ld h, a

                        ; Clear the display region.

                        ld de, 0000
CS_Mask                 equ * - 2

                        ld c, 3         ; Clear three sections of four lines.

CS_ClearFour            ld b, 4

CS_Loop                 ld a, (hl)
                        and d
                        ld (hl), a
                        inc l

                        ld a, (hl)
                        and e
                        ld (hl), a
                        dec l

                        inc h

                        djnz CS_Loop

                        dec c
                        ret z

                        ; Adjust the disp ptr in HL if necessary.

                        ld a, h
                        and %00000111
                        jp nz, CS_ClearFour

                        ld a, l
                        add a, 32
                        ld l, a
                        jp c, CS_ClearFour

                        ld a, h
                        sub a, 8
                        ld h, a
                        jp CS_ClearFour


