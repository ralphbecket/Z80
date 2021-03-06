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

Each row of cells takes 8 * 224 = 1,792 T-states for the scan beam to 
cover, or just less than the time it takes to draw 10 cells.  

This means that provided the mean number of cells on each row, scanning
row by row from top to bottom, never exceeds ten, then we will not be caught
by the beam (we have some early wiggle room because of the head start).  In
other words, I expect to manage a solid 40% screen occupancy going at full
tilt -- not too shabby.

Of course, this requires that we sort our bitmap drawing data by rows, but
we can do that in the alternate frames where we do not update the display.

BRAINWAVE!

The attribute copy can be made shorter and faster using stack tricks.
For example, copying 8 bytes like this

    ld SP, [src]
    pop AF, BC, DE, HL
    ld SP, [tgt + 8]
    push HL, DE, BC, AF

takes just 104 T-states and two fewer bytes than the 'ldi' scheme.  This
would cost 104 * 3 * 24 = 7,488 T-states, a saving of 2252 T-states or
enough for an extra 12.5 cells.  This would give us a head start of 37.5
cells

If it takes 181 T-states to draw a cell, and 7,488 T-states to copy the
attributes, then maximum occupancy of m-cells per row is given by

    7,488 + 24 * m * 181 = 14,336 + 24 * 1,792

or m = 11.5 cells per row.  That is very close to 50% occupancy in a 24x24
cell playing field!

DEMO

A Pac Man maze, scaled up to take 3x3 cell sprites, has 15% occupancy,
leaving plenty of capacity left over to handle the sprites.

I observe that the "draw in any order then sort" mechanism is too slow
to quite manage the full screen preparation and drawing in two frames.

I further observe that plotting the maze already happens in sorted order.
Therefore, we can save at least 33,000 Ts by simply building the draw
list as we plot the maze.  Hmm.  If we plot the maze bottom-up, we can 
use the stack to prepare the drawing list.  Now that would be quick!

Let's do it...
