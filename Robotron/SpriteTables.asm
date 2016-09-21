; These tables must be aligned on 256 byte boundaries.
PlayerTable             ds 256
BulletTable             ds 256
BotTable                ds 256
HumanTable              ds 256
HulkTable               ds 256

PlayerTimer             equ PlayerTable + 0
PlayerTimerReset        equ 2 ; Player moves every 2nd frame.
PlayerXY                equ PlayerTable + 1
PlayerAttr              equ Bright + WhiteInk

; Bullet info's are dx, dy, x, y.  A free bullet slot has dx = dy = 0.
BulletTableHi           equ BulletTable / 256
NextBulletLo            ds 1
MaxBullets              equ 4
TopBulletLo             equ 4 * MaxBullets
BulletAttr              equ Bright + CyanInk

; Bot info's are timer, x, y.  A free bot slot has timer = 0.
BotTableHi              equ BotTable / 256
MaxBots                 equ 32
TopBotLo                equ 3 * MaxBots
BotTimerReset           equ 5 ; Bots move every 5th frame.
BotAttr                 equ Bright + RedInk
NewBotTimer             ds 1
NewBotTimerReset        ds 1
InitNewBotTimerReset    equ 100

; XXX Add remaining table structures.

