                        zeusemulate "48k", "ula+"
Zeus_PC                 equ Main
Zeus_SP                 equ $0000
                        org $8000

                        ; ---- Constants ----

DisplayMap              equ $4000
AttrMap                 equ $5800
AttrMapSize             equ $300

Main                    xor a
                        out (254), a
mainLoop                call Keyboard
                        bit UpKeyBitNo, d
                        call nz, MoveMazeViewUp
                        bit DownKeyBitNo, d
                        call nz, MoveMazeViewDown
                        bit LeftKeyBitNo, d
                        call nz, MoveMazeViewLeft
                        bit RightKeyBitNo, d
                        call nz, MoveMazeViewRight
                zeustimerstart 1
                        call PlotMaze
                zeustimerstop 1
                        halt
                zeustimerstart 2
                        call RedrawDisplay
                zeustimerstop 2
                        jr mainLoop
                        di
                        halt



                        include "Colours.asm"
                        include "Keyboard.asm"
                        include "Bitmaps.asm"
                        include "Maze.asm"
                        include "Drawing.asm"   ; Put this last!


