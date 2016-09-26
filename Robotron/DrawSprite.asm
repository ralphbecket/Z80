; DrawSprite
;
; Draws a 12x12 px sprite on a 4px boundary.
;
; DE: yx for x in [0..61], y in [0..45]
; SMC: DrawSprite_Attr, DrawSprite_BitmapPtr
;
; NOTE: bitmaps must be in consecutive pairs where
; 2nd is at 4px offset and both are on the same 256 byte page.

DrawSprite              equ *

                        ; Calculate various SMC deltas.

                        xor a
                        srl e
                        jr nc, DS_SetBitmapPtrDelta
                        ld a, 24                ; Bytes in a 12x12px image.
DS_SetBitmapPtrDelta    ld (DS_BitmapPtrDelta), a
                        xor a
                        srl d
                        jr nc, DS_SetDispPtrDelta
                        ld a, 4
DS_SetDispPtrDelta      ld (DS_DispPtrDelta), a

                        ; Calculate the attr ptr.

                        ld a, d
                        rrca
                        rrca
                        rrca
                        ld l, a
                        and %00000111
                        add a, $58
                        ld h, a
                        ld a, l
                        and %11100000
                        or e
                        ld l, a                 ; Now HL = attr ptr.

                        ; Fill in the attributes.

                        ld de, 32
                        ld c, $ff
DrawSprite_Attr         equ * - 1

                        ld (hl), c
                        inc l
                        ld (hl), c
                        dec l
                        add hl, de
                        ld (hl), c
                        inc l
                        ld (hl), c
                        dec l
                        sbc hl, de

                        ; Convert HL from attr ptr to disp ptr.

                        ld a, h         ; A = %010110tt
                        add a, a
                        add a, a
                        add a, a        ; A = %110tt000
                        xor %10000000   ; A = %010tt000
                        add a, 00
DS_DispPtrDelta         equ * - 1
                        ld h, a

                        ; Draw the bitmap.

                        ld de, 0000
DrawSprite_BitmapPtr    equ * - 2
                        ld a, 00
DS_BitmapPtrDelta       equ * - 1
                        add a, e
                        ld e, a

                        ld c, 3         ; Draw three sections of four lines.

DS_DrawFour             ld b, 4

DS_Loop                 ld a, (de)
                        or (hl)
                        ld (hl), a
                        inc l
                        inc e

                        ld a, (de)
                        or (hl)
                        ld (hl), a
                        dec l
                        inc e

                        inc h

                        djnz DS_Loop

                        dec c
                        ret z

                        ; Adjust the disp ptr in HL if necessary.

                        bit 2, h
                        jp nz, DS_DrawFour

                        ld a, l
                        add a, 32
                        ld l, a
                        jp c, DS_DrawFour

                        ld a, h
                        sub a, 8
                        ld h, a
                        jp DS_DrawFour


