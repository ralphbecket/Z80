                        zeusemulate "48K", "ULA+"
ZeusEmulate_PC          equ Main
ZeusEmulate_SP          equ $FF40

                        org $8000

Main                    equ *

                        include "Init.asm"

MainLoop                call MoveRobots
                        call MoveBullets
                        call MovePlayer
                        call CheckCollisions
                        call AddNewRobots
                        call DrawScore
                        halt
                        jp MainLoop

                        halt
                        ret

                        include "Colours.asm"
                        include "DrawSprite.asm"
                        include "ClearSprite.asm"
                        include "Keyboard.asm"
                        include "Player.asm"
                        include "Bullets.asm"
                        include "Bots.asm"
                        include "Collisions.asm"
                        include "Score.asm"
                        include "Rnd.asm"
                        include "Util.asm"
                        include "Bitmaps.asm"

AllEnd                  equ *
AllLeft                 equ $8400 - AllEnd

                        org $9000
                        include "SpriteTables.asm"


