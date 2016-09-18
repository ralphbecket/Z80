 ; Ralph Becket's ZX Spectrum 256 Byte Game Challenge entry.

AppFilename     equ "Defender256"
AppFirst        equ $8000
                zeusemulate "48K", "ULA+"
ZeusEmulate_PC  equ Start
ZeusEmulate_SP  equ $FF40

                org AppFirst

Start           equ MainLoop

MainLoop        halt                    ; Wait for top-of-frame.
                halt

ClearScreen     ld hl, $5800
                ld de, $5801
                ld bc, $02ff
                ld (hl), %00000000
                ldir

DrawLandscape   ld a, (Offset)
                ld b, 32
                ld c, %00100000
                ld hl, $5800 + $0300 - $0020
dlLoop          bit 3, a                ; The landscape alternates bright/dim every 8 cells.
                jr z, dlDraw
                set 6, c
dlDraw          ld (hl), c
                inc l
                res 6, c
                inc a
                djnz dlLoop

MoveSprites     ld hl, Sprites
                push hl
NextSprite      pop hl
                ld a, (hl)              ; Jump target.
                inc hl
                ld d, (hl)              ; Y (rows from top of screen).
                inc hl
                ld e, (hl)              ; X (cells from left 'end' of game torus).
                inc hl
                push hl
                ld (JrSprite + 1), a    ; Self modifying code!
JrSprite       jr *

JrBase         equ *

JrAllDone      equ AllDone - JrBase
AllDone         pop hl
                jr MainLoop

JrSkip         equ NextSprite - JrBase

JrPlayer       equ Player - JrBase
Player          ld bc, $dffe
                in c, (c)
PlayerUpDown    inc d
                bit 4, c                ; 'Y' is up, else down.
                jr nz, PlayerYChk
                dec d
                jr z, PlayerLeftRight
                dec d
PlayerYChk      ld a, d
                cp 22
                jr c, PlayerLeftRight
                dec d
PlayerLeftRight push hl
                ld hl, Offset
                inc (hl)
                inc e
                bit 1, c                ; 'O' is reverse, else forward.
                jr nz, PlayerFire
                dec (hl)                ; No, we're heading left.
                dec (hl)
                dec e
                dec e
PlayerFire      pop hl
                ld a, (hl)              ; State of the laser.
                cp JrSkip
                jr nz, DrawPlayer
                bit 0, c                ; 'P' is fire.
                jr nz, DrawPlayer
                ld (hl), JrLaserRight
                bit 1, c
                jr nz, PlayerFireYX
                ld (hl), JrLaserLeft
PlayerFireYX    inc hl
                ld (hl), d              ; Laser Y.
                inc hl
                ld (hl), e              ; Laser X.
DrawPlayer      bit 1, c
                ld bc, %1111000100111010
                jr nz, DrawSprite
                ld bc, %1111000001111010
                jr DrawSprite

JrLaserLeft    equ LaserLeft - JrBase
LaserLeft       ld a, -6
                add a, e
                ld e, a

JrLaserRight   equ LaserRight - JrBase
LaserRight      inc e
                inc e
                inc e
                ld a, (Offset)
                add a, 30
                sub a, e
                jp m, LaserOffscreen
                jr nc, DrawLaser

LaserOffscreen  ld a, JrSkip           ; Laser is off the screen edge.
                ld (LaserSprite), a
                jr NextSprite

DrawLaser       ld bc, %1010000000111000
                jr DrawSprite

JrHumanoidStroll equ HumanoidStroll - JrBase
HumanoidStroll  ld hl, HumanoidTimer
                dec (hl)
                jr nz, DrawHumanoid
                inc e
                ld (hl), 3

DrawHumanoid    ld bc, %1110000110110010
                jr DrawSprite

JrLanderHunt   equ LanderHunt - JrBase
LanderHunt      ld hl, LanderTimer
                dec (hl)
                bit 0, (hl)
                jr nz, DrawLander
                inc e

DrawLander      ld bc, %1100000010111101
                jr DrawSprite



; hl = *sprite col, d = row, e = col, b = (attr << 1) | bit0, c = bit1.bit2....bit9
;
DrawSprite      pop hl
                push hl
                dec hl
                ld (hl), e              ; Update sprite row and column.
                dec hl
                ld (hl), d
                ld a, e                 ; Check sprite is on screen.
                sub 0                   ; Self modifying code!
Offset          equ $ - 1
                ld e, a
                cp 30
                jp nc, NextSprite
                ld a, d                 ; Calculate the top left sprite attr address.
                cp 22
                ret nc
                rrca
                rrca
                rrca
                ld l, a
                and $03
                add a, $58
                ld h, a
                ld a, l
                and $e0
                or e
                ld l, a

                srl b
                ld a, 3
                ld de, 32 - 2

dsCol0          jr nc, dsCol1           ; Draw three rows of three cells.
                ld (hl), b
dsCol1          inc l
                sla c
                jr nc, dsCol2
                ld (hl), b
dsCol2          inc l
                sla c
                jr nc, dsNextRow
                ld (hl), b
dsNextRow       add hl, de
                sla c
                dec a
                jr nz, dsCol0
                jp NextSprite

HumanoidTimer   db 3
LanderTimer     db 2

Sprites         equ *
PlayerSprite    db JrPlayer, 8, 14
LaserSprite     db JrSkip, 12, 16
Humanoid1Sprite db JrHumanoidStroll, 21, 49
Lander1Sprite   db JrLanderHunt, 4, 45
                db JrAllDone

                zeusprint "App code occupies ", * - Start, "bytes."
