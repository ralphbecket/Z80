                        zeusemulate "48k", "ula+"
Zeus_PC                 equ Main
Zeus_SP                 equ $0000
                        org $8000

                        ; ---- Constants ----

DisplayMap              equ $4000
AttrMap                 equ $5800
AttrMapSize             equ $300

                        include "Colours.asm"

                        ; N.B.: Display addresses are %01rrr000rrccccc.
                        ;       Attr addresses are    %01011rrrrrccccc.

Main                    halt

                        ; ---- Plotting (preparing for drawing). ----

; In:   a is attr.
;
ClearAttrs              ld hl, ShadowAttrMap
                        ld de, ShadowAttrMap + 1
                        ld bc, AttrMapSize - 1
                        or Flash
                        ld (hl), a
                        ldir
                        ret

; In:   h is row, l is column, c is attr.
; Out:  Z flag is set iff cell is already occupied.
; Note: No clipping is done: row, column must be in 0..23.
;
PlotAttr                ld a, h
                        rrca
                        rrca
                        rrca
                        ld h, a
                        and %11100000
                        or l
                        ld l, a
                        ld h, a
                        and %00000011
                        or high(ShadowAttrMap)
                        ld h, a                 ; hl is attr map cell pointer.
                        bit FlashBitNo, (hl)    ; The flash bit indicates "you can write here".
                        ret z
                        ; XXX Below is where we'd handle colour merging, if we want it.
                        ld (hl), c
                        ret

; In:   h is row, l is column, c is attr, de is bitmap ptr.
; Note: No clipping is done: row, column must be in 0..23.
;       Cells must be plotted in last-to-first order
;       across the whole display (i.e., lowest rows first).
;
PlotCell                call PlotAttr
                        ret z                   ; Already occupied.
                        inc h
                        inc h
                        inc h
                        ld (hl), e
                        inc h
                        ld (hl), d
                        ret

PrepareDrawList         ld hl, ShadowAttrMap
                        ld de, DrawList
                        ex af, af'
                        ld a, 0                 ; A' is draw list count.
                        ex af, af'
                        ld b, 24
pdlLoop         loop 24
                        bit FlashBitNo, (hl)
                        call z, pdlAddDrawCell
                        inc l
                lend
                        ld a, 8
                        add a, l
                        ld l, a
                        adc a, h
                        sub l
                        ld h, a
                        dec b
                        jp nz, pdlLoop
                        ex af, af'
                        ld (NumCellsToDraw), a
                        ex af, af'
                        ret

pdlAddDrawCell          ex af, af'
                        inc a
                        ex af, af'
                        ld a, l
                        ld (de), a
                        inc de
                        ld a, h
                        xor high(ShadowAttrMap ^ (DisplayMap / 8))
                        add a, a
                        add a, a
                        add a, a
                        ld (de), a
                        inc de
                        inc h
                        inc h
                        inc h
                        ld a, (hl)
                        ld (de), a
                        inc de
                        inc h
                        ld a, (hl)
                        ld (de), a
                        inc de
                        dec h
                        dec h
                        dec h
                        dec h
                        ret

                        ; ---- Drawing ----

RedrawDisplay           call DrawAttrs
                        call DrawCells
                        ret

DrawAttrs               ld hl, ShadowAttrMap
                        ld de, AttrMap
                loop AttrMapSize                ; We can trade off space for speed if needed.
                        ldi
                lend
                        ret

DrawCells               ld (SavedSP), sp
                        ld sp, DrawList
                        ld a, (NumCellsToDraw)
                        ld b, a
dcsLoop                 pop hl                  ; Display pointer.
                        pop de                  ; Bitmap pointer.
dcsDrawCell             ld a, (de)
                        ld (hl), a
                loop 7
                        inc e
                        inc h
                        ld a, (de)
                        ld (hl), a
                lend
                        djnz dcsLoop
                        ld sp, (SavedSP)
                        ret

                        ; ---- Storage ----

; We use the following arrangement for the shadow attr map
; and to track and order which cells have bitmaps to be drawn.
; A shadow attr map cell with the flash bit set has no bitmap.
; Otherwise, the attr map cell at address x has a bitmap whose
; address is found at x + $300 and x + $400 (lo and hi bytes
; respectively).

NumCellsToDraw          dw 0
SavedSP                 dw 0
SavedAttr               dw 0

                        org $ee00
ShadowAttrMap           ds AttrMapSize
CellBitmapsLo           ds AttrMapSize
CellBitmapsHi           ds AttrMapSize
DrawList                ds 24 * 24 * 4
Fin                     db 0

