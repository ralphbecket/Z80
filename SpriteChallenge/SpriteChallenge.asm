                emulate_spectrum "48k"
                output_szx "SpriteChallenge.szx", 0, Start
                org $8000

Start           ld hl, $4000    ; Clear the display.
                ld de, $4001
                ld bc, $1800
                ld (hl), $22
                ldir
                ld (hl), 7 * 8
                ld bc, $300 - 1
                ldir

                ld hl, $8060    ; Animate a sprite.
                ld b, 256 / 3
                ld de, GhostSprite
Lp              push hl
                push de
                push bc
                call DrawSprite
                pop bc
                pop de
                pop hl
                ld a, 3: add a, h: ld h, a
                ld a, 3: add a, l: ld l, a
                djnz Lp
                halt

; hl = XY, de = src.
;
; Sprite data is 16 words of inverted mask (i.e., a 0 denotes the
; corresponding screen pixel is to be preserved) followed by 16
; words of bitmap.
;
; Internally, we keep XY and the offset IJ (I, J in 0..15) in
; one register bank, and we keep the sprite pointer and row bits
; in another register bank.

profile = true

DrawSprite      push de         ; Set-up code.
                exx
                pop de          ; Src = Src - 2
                exx
                ld de, $0fff    ; I = 15, J = -1
                push de
                ld (XY), hl
                ld c, 0         ; c = 0 => Masking.
                call NextI
                inc c           ; c = 1 => Drawing.
                pop de          ; I = 15, J = -1

NextI           inc d           ; I = I + 1
                bit 4, d        ; I == 16 ?
                jr z, Plot

NextJ           inc e           ; J = J + 1
                bit 4, e        ; J == 16 ?
                ret nz
                ld d, 0

FetchRow        exx
                ld a, (de)      ; Bits := Src[0].Src[1]
                ld h, a         ; Src += 2
                inc de
                ld a, (de)
                ld l, a
                inc de
                exx

Plot            ld hl, 00       ; h = X, l = Y -- SMC!
XY              equ $ - 2
                add hl, de      ; h = X + I, l = Y + J
                jr c, NextJ     ; If 256 <= X + I

                ld a, l
                cp 192          ; Y + J < 192 ?
                jr nc, NextJ

ScrPos          push de
                ex de, hl       ; Provided by John Metcalf.
                ld a, d
                and 7
                ld b, a         ; b = num px from left in byte.
                ld a, e
                rra
                scf
                rra
                or a
                rra
                ld l, a
                xor e
                and 248
                xor e
                ld h, a
                ld a, l
                xor d
                and 7
                xor d
                rrca
                rrca
                rrca
                ld l, a         ; hl = display byte addr.
                pop de

FetchBit        exx
                xor a
                add hl, hl
                rra             ; a = msb(Bits), Bits <<= 1
                exx

RotateBit       rrca            ; a <<= b
                djnz RotateBit  ; No prizes for speed :-)

; Mask or draw the bit.
                bit 0, c
                jr z, MaskBit

DrawBit         or (hl)
                ld (hl), a
                jr NextI

MaskBit         cpl
                and (hl)
                ld (hl), a
                jr NextI

ZZZDrawSpriteSize equ $ - DrawSprite

profile = false

GhostSprite     dg .....xxxxxx.....
                dg ...xxxxxxxxxx...
                dg ..xxxxxxxxxxxx..
                dg .xxxxxxxxxxxxxx.
                dg .xxxxxxxxxxxxxx.
                dg .xxxxxxxxxxxxxx.
                dg xxxxxxxxxxxxxxxx
                dg xxxxxxxxxxxxxxxx
                dg xxxxxxxxxxxxxxxx
                dg xxxxxxxxxxxxxxxx
                dg xxxxxxxxxxxxxxxx
                dg xxxxxxxxxxxxxxxx
                dg xxxxxxxxxxxxxxxx
                dg xxxxxxxxxxxxxxxx
                dg .xxxx.xxxx.xxxx.
                dg ..xx...xx...xx..

                dg .....xxxxxx.....
                dg ...xx......xx...
                dg ..x..........x..
                dg .x.xx....xx...x.
                dg .xx..x..x..x..x.
                dg .xxx.x..xx.x..x.
                dg x.xx.x..xx.x...x
                dg x.xx.x..xx.x...x
                dg x..xx....xx....x
                dg x..............x
                dg x..............x
                dg x..............x
                dg x..............x
                dg x....x....x....x
                dg .x..x.x..x.x..x.
                dg ..xx...xx...xx..


