; These tables must fit within 256 byte page boundaries.

StartOfTables           equ *

PlayerTable             ds 256
BulletTable             ds 256
BotTable                ds 256
ScoreDigits             ds NumScoreDigits

;HumanTable              ds 256
;HulkTable               ds 256

PlayerTimer             equ PlayerTable + 0
PlayerTimerReset        equ 2 ; Player moves every 2nd frame.
PlayerXY                equ PlayerTable + 1
PlayerAttr              equ Bright + WhiteInk

; Bullet info's are dx, dy, x, y.  A free bullet slot has dx = dy = 0.
BulletTableHi           equ BulletTable / 256
MaxBullets              equ 4
TopBulletLo             equ 4 * MaxBullets
BulletAttr              equ Bright + CyanInk

; Bot info's are timer, x, y.  A free bot slot has timer = 0.
BotTableHi              equ BotTable / 256
MaxBots                 equ 24
TopBotLo                equ 3 * MaxBots
BotTimerReset           equ 5 ; Bots move every 5th frame.
BotAttr                 equ Bright + RedInk
NewBotTimer             ds 1
BotsPerWave             ds 1
InitBotsPerWave         equ 5
NewBotTimerReset        equ 51 ; Coprime with BotTimerReset.

; Scoring.
NumScoreDigits          equ 6
ScoreDigitsHi           equ ScoreDigits / 256

; XXX Add remaining table structures.

EndOfTables             equ *
SizeOfTables            equ EndOfTables - StartOfTables
