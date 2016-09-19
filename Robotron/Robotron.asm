                zeusemulate "48K", "ULA+"
ZeusEmulate_PC  equ Main
ZeusEmulate_SP  equ $FF40

                org $8000

Main            equ *

                ld a, MagentaPaper
                call ClearScreen
                call InitRnd
                call InitPlayer
                call InitBullets
                call InitRobots
                ld a, 5
                ld (BotTable), a

MainLoop        call MoveRobots
                call MoveBullets
                call MovePlayer
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
                include "Rnd.asm"
                include "Util.asm"
;                include "TestClearSprite.asm"
;                include "TestDrawSprite.asm"
;                include "TestBitmap.asm"
                org $9000
                include "SpriteTables.asm"
                org $f000
                include "Bitmaps.asm"

