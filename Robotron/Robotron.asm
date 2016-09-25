                        zeusemulate "48K", "ULA+"
ZeusEmulate_PC          equ Main
ZeusEmulate_SP          equ $FF40

                        org $8000

Main                    equ *

                        xor a
                        call ClearScreen
                        call InitRnd
                        call InitPlayer
                        call InitBullets
                        call InitRobots

MainLoop                call MoveRobots
                        call MoveBullets
                        call MovePlayer
                        call CheckCollisions
                        call AddNewRobots
                        halt
                        jp MainLoop

                        halt
                        ret

                        include "Colours.asm"
                        include "DrawSprite.asm"
                        include "ClearSprite.asm"
                        include "ClearScreen.asm"
                        include "Keyboard.asm"
                        include "Player.asm"
                        include "Bullets.asm"
                        include "Bots.asm"
                        include "Collisions.asm"
                        include "Rnd.asm"
                        include "Util.asm"
                        include "Bitmaps.asm"

End                     equ *

                        org $9000
                        include "SpriteTables.asm"


