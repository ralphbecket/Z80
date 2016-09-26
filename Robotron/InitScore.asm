InitScore               ld hl, ScoreDigits
                        ld de, ScoreDigits + 1
                        ld bc, NumScoreDigits - 1
                        ld (hl), DigitBotLo
                        ldir
