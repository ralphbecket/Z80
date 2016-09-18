                        zeusemulate "48K","ULA+"
                        Zeus_PC = Main
                        Zeus_SP = $0000

                        org $8000

Main                    ld hl, Attrs - 1

MainLoop                halt

Scroll                  ld de, Attrs
                        ld (hl), e
                        ld bc, 24 * 32
                        ldir

Draw                    ld hl, Attrs + 31
                        ld de, 32
                        ld b, 8
                        ld ix, RomChars + 8 * 'W'
BitsPtr                 equ * - 2

DrawLoop                ld a, (ix + 0)
                        inc ix
                        and %10000000
Bit                     equ * - 1
                        ld (hl), a
                        jr z, DrawNextDown
                        ld (hl), $ff

DrawNextDown            add hl, de
                        djnz DrawLoop

NextCol                 ld hl, Bit
                        ld a, (hl)
                        rrca
                        ld (hl), a
                        jr nc, NextFrame

NextCh                  ld hl, Msg
Ch                      equ * - 2
                        inc l
                        jr nz, CalcBitsPtr
                        ld l, Msg & $00ff
CalcBitsPtr             ld (Ch), hl
                        ld a, (hl)
                        add a, a
                        ld l, a
                        ld h, (RomChars / $0100) / 4
                        add hl, hl
                        add hl, hl
                        ld (BitsPtr), hl

NextFrame               halt
                        ld hl, Attrs + 1
                        jr MainLoop

CodeSize                equ * - Main

                        org $8100 - MsgSize

Msg                     db "Welcome to the Z80 Assembly Programming "
                        db "On The ZX Spectrum Compo #7 "
                        db "ScrollText......"
MsgEnd                  equ *           ; Must be on a page boundary.
MsgSize                 equ 84
RomChars                equ $3c00
Attrs                   equ $5800

                        zeusprint CodeSize + MsgSize, "bytes"
