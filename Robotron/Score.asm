IncScore                ld hl, ScoreDigits + NumScoreDigits - 1

IS_Loop                 ld a, (hl)
                        inc a
                        cp DigitTopLo
                        jr nc, IS_Carry
                        ld (hl), a
                        ret

IS_Carry                ld (hl), DigitBotLo
                        dec l
                        jr IS_Loop



DrawScore               ld b, NumScoreDigits

DSC_Loop                push bc

DrawScoreDigit          ld h, ScoreDigitsHi
                        ld l, b
                        dec l
                        ld l, (hl)
                        ld h, DigitBotHi
                        ld c, (hl)

DSD_CalcAttrPtr         ld a, b
                        add a, a
                        add a, b
                        add a, 3 * 32 + 1
                        ld h, $5a
                        ld l, a

                        ld b, 4
                        ld de, 32 - 1

DSD_Loop                ld a, YellowInk
                        sla c
                        jr nc, DSD_WriteLeftPx
                        ld a, YellowPaper
DSD_WriteLeftPx         ld (hl), a
                        inc l

                        ld a, YellowInk
                        sla c
                        jr nc, DSD_WriteRightPx
                        ld a, YellowPaper
DSD_WriteRightPx        ld (hl), a
                        add hl, de

                        djnz DSD_Loop

                        pop bc
                        djnz DSC_Loop

                        ret

