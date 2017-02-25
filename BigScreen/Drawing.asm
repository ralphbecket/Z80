                        ; N.B.: Display addresses are %01rrr000rrccccc.
                        ;       Attr addresses are    %01011rrrrrccccc.

                        ; ---- Plotting (preparing for drawing). ----

; In:   h is row, l is column, c is attr.
; Out:  C flag is set iff cell is offscreen.
;       Z flag is set iff cell is already occupied.
;
ClipAttr                ld a, 32
                        cp h
                        ret nc
                        cp l
                        ret nc

; In:   h is row, l is column, c is attr.
; Out:  Z flag is set iff cell is already occupied.
; Note: No clipping is done: row must be in 0..23, column must be in 0..31.
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
; Note: Plot a cell iff it is visible on screen.
;       Cells must be plotted in last-to-first order
;       across the whole display (i.e., lowest rows first).
;
ClipCell                call ClipAttr
                        ret z                   ; Already occupied.
                        ret c                   ; Offscreen.
                        inc h
                        inc h
                        inc h
                        ld (hl), e
                        inc h
                        ld (hl), d
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
                        inc h
                        inc h
                        ld (hl), d
                        ret

; Plot a row of attributes, clipping to the screen boundaries.
; In:   h is row, l is left column, b is width, c is attr.
;
ClipAttrRow             ld a, l
carClipLeft             cp 32
                        jr nc, carStart
                        inc l
                        djnz carClipLeft
                        ret
carStart                ld d, l
                        call PlotAttr
carLoop                 inc d
                        ld a, d
                        cp 32
                        ret nc
                        inc l
                        bit FlashBitNo, (hl)
                        jr z, carNext
                        ld (hl), c
carNext                 djnz carLoop
                        ret


; Plot a columns of attributes, clipping to the screen boundaries.
; In:   h is top row, l is column, b is height, c is attr.
;
ClipAttrCol             ld a, h
cacClipLeft             cp 24
                        jr nc, cacStart
                        inc h
                        djnz cacClipLeft
                        ret
cacStart                ld d, h
                        call PlotAttr
cacLoop                 inc d
                        ld a, d
                        cp 24
                        ret nc
                        ld a, l
                        add a, 32
                        ld l, a
                        adc a, h
                        sub a, l
                        ld h, a
                        bit FlashBitNo, (hl)
                        jr z, cacNext
                        ld (hl), c
cacNext                 djnz cacLoop
                        ret

; Plot a sprite, clipping to the screen boundaries.
; In:   h is top row, l is left column, b is width, c is height, de points to cell list.
;       The sprite cell list is a sequence of (attr, bitmap ptr) pairs.
;
ClipSprite              ; XXX HERE!

; ---- Preparing the draw list. ----
; Only use this function if you are using the PlotCell functions
; out of order.  This function is expensive and it's better, if
; possible, to arrange the draw list manually by plotting things
; in the correct order in the first place.

PrepareDrawList         ld hl, ShadowAttrMap
                        ld de, DrawList
                        ld ixh, 0                 ; Draw list count.
                        ld bc, -$600
                        ld ixl, 24                ; Row loop counter.
pdlLoop         loop 32
                        bit FlashBitNo, (hl)
                        call z, pdlAddDrawCell
                        inc l
                lend
                        dec l
                        inc hl
                        ;ld a, 8
                        ;add a, l
                        ;ld l, a
                        ;adc a, h
                        ;sub l
                        ;ld h, a
                        dec ixl
                        jp nz, pdlLoop
                        ld a, ixh
                        ld (NumCellsToDraw), a
                        ret

pdlAddDrawCell          inc ixh
                        ld a, l
                        ld (de), a
                        inc de
                        ld a, h
                        sub a, high(ShadowAttrMap)
                        add a, a
                        add a, a
                        add a, a
                        add a, high(DisplayMap)
                        ld (de), a
                        inc de
                        inc h
                        inc h
                        inc h
                        ld a, (hl)
                        ld (de), a
                        inc de
                        inc h
                        inc h
                        inc h
                        ld a, (hl)
                        ld (de), a
                        inc de
                        add hl, bc
                        ret

                        ; ---- Drawing ----

RedrawDisplay           call DrawAttrs
                        call DrawCells
                        ret

PlotClearScreen         ld hl, ShadowAttrMap
                        ld de, ShadowAttrMap + 1
                        ld ixl, 24
                        ld b, 0                 ; XXX This could go faster using the stack.
dclsLoop                ld (hl), a
                        ;ld c, 32
                loop 32
                        ldi
                lend
                        ;add hl, bc
                        ;ex de, hl
                        ;add hl, bc
                        ;ex de, hl
                        dec ixl
                        jp nz, dclsLoop
                        ret

DrawAttrs               ld hl, ShadowAttrMap
                        ld de, AttrMap
                        ld a, 24
                        ;ld b, 0                 ; XXX This could go faster using the stack.
dasLoop                 ld c, 32
                loop 32
                        ldi
                lend
                        ;add hl, bc
                        ;ex de, hl
                        ;add hl, bc
                        ;ex de, hl
                        dec a
                        jp nz, dasLoop
                        ret

DrawCells               ld (SavedSP), sp
                        ld sp, (DrawListBot)
                        ld a, (NumCellsToDraw)
                        and a
                        jp z, dcsExit
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
 ;halt
 ;halt
                        djnz dcsLoop
dcsExit                 ld sp, (SavedSP)
                        xor a
                        ld (NumCellsToDraw), a
                        ret

; ---- Storage ----

; We use the following arrangement for the shadow attr map
; and to track and order which cells have bitmaps to be drawn.
; A shadow attr map cell with the flash bit set has no bitmap.
; Otherwise, the attr map cell at address x has a bitmap whose
; address is found at x + $300 and x + $400 (lo and hi bytes
; respectively) -- unless the user is plotting things in order
; and is manually constructing the draw list.

NumCellsToDraw          dw 0
SavedSP                 dw 0
SavedAttr               dw 0
DrawListBot             dw DrawList

                        org $ed00
ShadowAttrMap           ds AttrMapSize
CellBitmapsLo           ds AttrMapSize
CellBitmapsHi           ds AttrMapSize
DrawList                ds 24 * 24 * 4
DrawListTop             equ *

