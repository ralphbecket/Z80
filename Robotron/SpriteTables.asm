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

; Bullet info's are dx, dy, x, y.
BulletTableHi           equ BulletTable / 256
NextBulletLo            db 0
TopBulletLo             equ 4 * 32
BulletAttr              equ Bright + CyanInk

; Bot info's are timer, x, y.  A dead bot has timer = 0.
BotTableHi              equ BotTable / 256
TopBotLo                equ 3 * 64 ; Should be enough!
BotTimerReset           equ 5
BotAttr                 equ Bright + RedInk

; XXX Add remaining table structures.

