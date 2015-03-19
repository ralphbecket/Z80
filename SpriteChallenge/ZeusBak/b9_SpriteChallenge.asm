                emulate_spectrum "48k"
                output_szx "SpriteChallenge.szx", 0, Start
                org $8000

; Clear the display.
Start           ld hl, $4000
                ld de, $4001
                ld bc, $1B00 - 1
                ld (hl), $87
                ldir
                halt

; hl = xy, de = src.
DrawSprite      ld (XY), hl
                ld hl, 00
                ld (IJ), hl
                ld (Src), de
                ld a, (de)
                ld l, a
                inc de
                ld a, (de)
                ld h, a
                ld (Bits), hl

; Fetch the display address at (XY) + (IJ).
MainLp          ld hl, 00
XY              equ $ - 2
                ld de, 00
IJ              equ $ - 2
                add hl, de
                jr nc, ChkYJ
; We've passed the right edge of the screen.
; Advance to the next row.
NextRow         ld d, 0
                inc e
                bit 4, e        ; 16 < J?
                ret nz
; Fetch the next row of bitmap data.
                ld hl, 00
Src             equ $ - 2
                inc hl
                inc hl
                ld (Src), hl
                ld a, (hl)
                inc hl
                ld h, (hl)
                ld l, a
                ld (Bits), hl
                jr MainLp
; Check we haven't hit the bottom of the display.
ChkYJ           ld a, l
                cp 192
                ret nc
; Increment IJ for the next iteration.
                inc e
                ld (IJ), de
; Convert hl = (XY) + (IJ) into a display address and pixel offset.
; hl = xy; hl = disp addr, b = pixel in byte from left (0..7).
ScrPos          ex de, hl
                ld a, d
                and 7
                ld b, a
                ld a, e
                rra
                scf
                rra
                or a
                rra
                ld l, a
                xor e
                ld h, a
                ld a, l
                xor d
                and 7
                xor d
                rrca
                rrca
                rrca
                ld l, a
; Fetch the next bit to emit and rotate it into position.
                ld hl, 00
Bits            equ $ - 2
                xor a
                add hl, hl
                rra
RotLp           rrca
                djnz RotLp      ; This won't win prizes for speed!
; XXX Mask or draw the bit.
Draw            or (hl)
                ld (hl), a
                jr MainLp
Mask            cpl
                and (hl)
                ld (hl), a
                jr MainLp

