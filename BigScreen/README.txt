This is an attempt to see how much of the screen I can have updating at
25 FPS (one frame of drawing, one of set-up) on the standard 48K ZX Spectrum,
without restricting what may appear on the screen.

I think I can manage a 24x24 cell region with about 40% occupancy (i.e.,
about ten cells in each row containing new bitmap data).

The idea is this: I have a shadow attribute map which I copy to the display at
the start of the screen refresh interrupt.  Then I have an ordered list of
(screen address, bitmap address) pairs for cells to be drawn.

The attribute copy routine will be something of this order:

    ld HL, ShadowAttrMap
    ld DE, RealAttrMap
    loop 24
        loop 24
            ldi
        lend
        ld BC, 8
        add HL, BC
    lend

for 10 + 10 + 24 * (24 * 16 + 10 + 11) = 9,740 T-states.

The scan beam takes 14,336 T-states to reach the bitmap region of the display,
giving us a 4,596 T-state head start on the bitmap data.

The bitmap data will be drawn by something like this code:

    ld SP, StartOfDrawList
    ld B, NumCellsToDraw
DrawBitmapLoop:
    pop DE      ; Source bitmap address.
    pop HL      ; Target display cell address.
    loop 8
        ld A, (DE)
        ld (HL), A
        inc H
        inc E
    lend
    equ * - 2   ; Overwrite the redundant trailing 'inc's.
    djnz DrawBitmapLoop

for 8 * (7 + 7 + 4 + 4) - (4 + 4) + 13 = 181 T-states per drawn cell.

The 4,596 T-state head-start allows us to draw 25 cells.

Each row of cells takes 8 * 224 = 1,792 T-states to draw, or just less
than the time it takes to draw 10 cells.  

This means that provided the mean number of cells on each row, scanning
row by row from top to bottom, never exceeds ten, then we will not be caught
by the beam (we have some early wiggle room because of the head start).  In
other words, I expect to manage a solid 40% screen occupancy going at full
tilt -- not too shabby.

Of course, this requires that we sort our bitmap drawing data by rows, but
we can do that in the alternate frames where we do not update the display.

