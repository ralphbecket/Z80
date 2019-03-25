; Main.asm

        zeusemulate "48K","ULA+"

AppFirst                equ $8000                       ; First byte of code (uncontended memory).
AppFilename             equ "MegaPacMan"                ; What we're called (for file generation).

; Setup the emulation registers, so Zeus can emulate this code correctly

Zeus_PC                 equ Main                        ; Tell the emulator where to start.
Zeus_SP                 equ $FF40                       ; Tell the emulator where to put the stack.

        org AppFirst

Main proc
        call InitSprites
        ; Wait for the frame refresh interrupt.
_1      ei
        halt
        ; Point DE to the maze address centring the red ghost.
        ; Yes, this is slightly horrible.
        ld DE, (RedSpriteData + SpriteMazeAddrLo)
_V1     ld A, D
        sub high(Maze) + (DisplayHeight / 2)
        jr nc, _V2
        ld A, 0
_V2     cp (MazeHeight - DisplayHeight)
        jr c, _V3
        ld A, MazeHeight - DisplayHeight
_V3     add high(Maze)
        ld D, A
_H1     ld A, E
        sub 2 * (DisplayWidth / 2)
        jr nc, _H2
        ld A, 0
_H2     cp 2 * (MazeWidth - DisplayWidth)
        jr c, _H3
        ld A, 2 * (MazeWidth - DisplayWidth)
_H3     ld E, A
        ; Now we are centred on the red ghost.
        call PrepRedrawMaze
        call RedrawMaze
        call RestoreMazeAfterRedraw
        call UpdateSprites
        jp _1
endp

        include "Display.asm"
        include "Sprites.asm"
        include "Maze.asm"

; Stop planting code after this. (When generating a tape file we save bytes below here)
AppLast                 equ $                           ; The last used byte's address

                        zeusprint AppLast - AppFirst, "bytes"

; Generate some useful debugging commands

                        ; profile AppFirst, AppLast

