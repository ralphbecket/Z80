                zeusemulate "48K", "ULA+"
ZeusEmulate_PC  equ Main
ZeusEmulate_SP  equ $FF40

                org $8000

MinWhite        equ 7
MinRed          equ MinWhite + 1
TopRed          equ MinRed + 2
TopWhite        equ TopRed + 1
Height          equ TopWhite + MinWhite - 2
Width           equ TopWhite + 2 * MinWhite - 1

White           equ %01111000
Red             equ %01010000
Blue            equ %01001000

Main            ld hl, $5800 + ((Height - 1) * 32) + (Width - 1)
                ld c, Height

YLoop           ld b, Width

XLoop           ld (hl), Red
                ld de, MinRed * $100 + TopRed
                call Test
                jr c, Next

                ld (hl), White
                ld de, MinWhite * $100 + TopWhite
                call Test
                jr c, Next

                ld (hl), Blue

Next            dec hl
                djnz XLoop
                ld de, -(32 - Width)
                add hl, de
                dec c
                jr nz, YLoop
                ret

Test            equ *
TestX           ld a, b
                cp d
                jr c, TestY
                cp e
                ret c
TestY           ld a, c
                cp d
                ccf
                ret nc
                cp e
                ret

