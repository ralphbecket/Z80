                        zeusemulate "48k", "ula+"
Zeus_PC                 equ Main
Zeus_SP                 equ $FF00
                        org $8000

                        ; ---- Constants ----

DisplayMap              equ $4000
AttrMap                 equ $5800
AttrMapSize             equ $300

Main                    xor a
                        out (254), a
                        ld a, Flash + BlackInk + MagentaPaper
                        call PlotMaze
                        call PrepareDrawList
                zeustimerstart 1
                        call RedrawDisplay
                zeustimerstop 1
                        halt
                        halt
                        di
                        halt



                        include "Colours.asm"
                        include "Keyboard.asm"
                        include "Bitmaps.asm"
                        include "Maze.asm"
                        include "Drawing.asm"   ; Put this last!


