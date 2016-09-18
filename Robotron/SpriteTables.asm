; These tables must be aligned on 256 byte boundaries.
PlayerTable             ds 256
BulletTable             ds 256
BotTable                ds 256
HumanTable              ds 256
SquasherTable           ds 256

PlayerTimer             equ PlayerTable + 0
PlayerTimerReset        equ 2 ; Player moves every 2nd frame.
PlayerXY                equ PlayerTable + 1
PlayerAttr              equ Bright + WhiteInk

; Bullet info's are dx, dy, x, y.
BulletTableHi           equ BulletTable / 256
NextBulletLo            db 0
LastBulletLo            equ 4 * 32
BulletAttr              equ Bright + CyanInk

; XXX Add remaining table structures.

