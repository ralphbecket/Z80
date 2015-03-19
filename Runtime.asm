; Fix all references to runtime addresses so they match once we
; copy the runtime system to the start of the generated code.

Reloc           ld hl, (CodeBase)
                ld de, RuntimeBase
                xor a
                sbc hl, de
                ld (rRelocDelta), hl
                call rReloc

                ld hl, RuntimeBase
                ld bc, RuntimeLength
                call Gen
                ret

rReloc          ld (rSavedSP), sp
                ld sp, RelocTable
                ld b, h
                ld c, l

rLp             pop hl
                ld a, h
                or l
                jp z, rDone
                ld e, (hl)
                inc hl
                ld d, (hl)
                ex de, hl
                xor a
                add hl, bc
                ex de, hl
                ld (hl), d
                dec hl
                ld (hl), e
                jp rLp

rDone           ld sp, (rSavedSP)
                ret

; Reset references to runtime addresses after relocation in
; case we want to re-run the compiler.

UnReloc         ld de, (rRelocDelta)
                ld hl, 0
                xor a
                sbc hl, de
                call rReloc

                ld hl, 0
                ld (rRelocDelta), hl
                ret

RuntimeBase     jp RuntimeEnd

; hl = hl * de
rMul            ld a, h
                ld c, l
                ld b, 16
rMulLp          add hl, hl
                sla c
                rla
                jr nc, rMulNoAdd
                add hl, de
rMulNoAdd       djnz rMulLp
                ret

; hl = de / hl
rUDiv           xor a
                jr rDiv2
rDiv            push de
                ex de, hl
                xor a
                bit 7, d
                jr z, rDiv1
                cpl
                ld hl, 0
                sbc hl, de
                ex de, hl
rDiv1           pop bc
                bit 7, b
                jr z, rDiv2
                cpl
                and a
                ld hl, 0
                sbc hl, bc
                ld b, h
                ld c, l
rDiv2           push af
                ld a, b
                ld hl, 0
                ld b, 16
rDivLp          rl c
                rla
                adc hl, hl
                sbc hl, de
                jr nc, rDivEndLp
                add hl, de
rDivEndLp       ccf
                djnz rDivLp
rDivDone        rl c
                rla
                ld h, a
                ld l, c
                pop af
                and a
                ret z
                ex de, hl
                ld hl, 0
                xor a
                sbc hl, de
                ret

                ; ...
RuntimeEnd      equ $
RuntimeLength   equ RuntimeEnd - RuntimeBase
