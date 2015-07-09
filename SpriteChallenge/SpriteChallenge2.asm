                emulate_spectrum "48k"
                output_szx "SpriteChallenge2.szx", 0, Start
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
                ld de, TestSprite
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

TestSprite      db %11111100,%00111111, %00000000,%00000000
                db %11110000,%00001111, %00000011,%11000000
                db %11100000,%00000111, %00001100,%00110000
                db %11000000,%00000011, %00010000,%00001000
                db %10000000,%00000001, %00100010,%00000100
                db %10000000,%00000001, %00100111,%00000100
                db %00000000,%00000000, %01000010,%00010010
                db %00000000,%00000000, %01000000,%00001010
                db %00000000,%00000000, %01000000,%00010010
                db %00000000,%00000000, %01000000,%00101010
                db %10000000,%00000001, %00100000,%01010100
                db %10000000,%00000001, %00100010,%10100100
                db %11000000,%00000011, %00010001,%01001000
                db %11100000,%00000111, %00001100,%00110000
                db %11110000,%00001111, %00000011,%11000000
                db %11111100,%00111111, %00000000,%00000000

                ds $90

; In: de = XY, hl = src.
DrawSprite      ld a, 16
                add a, e
                ex af, af'      ; a' = Y + 16




ScrPos          push de
                push hl         ; Stk = [Src, XY, ...]
                ld a, d
                and 7
                xor 7
                inc a
                ld b, a         ; b = num px from right in next byte.
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

Fetch           ex (sp), hl     ; hl = Src, Stk = [Disp, XY, ...]
                ld a, $ff
                ld d, (hl)
                inc hl
                ld e, (hl)
                inc hl
                push hl
                ex de, hl       ; ahl = unshifted mask bits.
                exx
                pop hl
                ld c, 0
                ld d, (hl)
                inc hl
                ld e, (hl)
                inc hl
                push hl
                ex de, hl       ; c'h'l' = unshifted pattern bits.
                exx             ; Stk = [Src, Disp, XY, ...]

Shift           scf
                adc hl, hl
                rla
                exx
                or a
                add hl, hl
                rl c
                exx
                djnz Shift
                ex de, hl       ; ade = shifted mask, c'h'l' = shifted pattern.

                pop hl
                ex (sp), hl     ; hl = Disp, Stk = [Src, XY, ...]
                ld c, l         ; Used to watch bit 5 for changes.

Draw            and (hl)
                exx
                or c
                ld c, d
                ld d, e
                exx
                ld (hl), a
                inc l
                ld a, l
                xor c
                bit 5, a        ; nz iff bit 5 changed.
                ld a, d
                ld d, e
                jr z, Draw



ZDrawSpriteSize equ $ - DrawSprite

