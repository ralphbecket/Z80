                emulate_spectrum "48k"
                output_szx "ClearChallenge.szx", 0, Start
                org $8000

Start           ld hl, $4000            ; Clear the display.
                ld de, $4001
                ld bc, $1800
                ld (hl), $55
                ldir
                ld (hl), 7 * 8          ; White paper, black ink.
                ld bc, $300 - 1
                ldir
                ei
                call Clear
                di
                halt

                ; If cells are addressed by (row, column) in (c, b)
                ; for c in 1..24, b in 1..32, then we need to increment
                ; the ink colour of cells in the diagonal stripe satisfying
                ;       t - 7 <= c + b - 2 < t
                ; for a parameter t ranging from 1..62 (32 + 24 - 1 + 7 = 62),
                ; incremented once per frame.
                ;
                ; This gives us a condition:
                ;       t - 7 <= c + b - 2 < t
                ; <=>   0 <= c + b - t + 5 < 7
                ;
                ; Now, it is slightly shorter to count backwards with the Z80,
                ; so let d = 62 - t, hence t = 62 - d, and substitute giving
                ;       0 <= c + b + d - 57 < 7

Clear           proc
                ld d, 61
PageLp          halt
                ld hl, $5800 + $2ff
                ld c, 24
RowLp           ld b, 32
CellLp          ld a, b
                add a, c
                add a, d
                add a, -57
                cp 7
                jr nc, Next
                inc (hl)
Next            dec hl
                djnz CellLp
                dec c
                jr nz, RowLp
                dec d
                jr nz, PageLp
                ret
                endp

ZClearSize      equ $ - Clear
