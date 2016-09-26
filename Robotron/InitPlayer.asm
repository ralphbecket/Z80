InitPlayer              ld a, PlayerTimerReset
                        ld (PlayerTimer), a
                        ld hl, $151e
                        ld (PlayerXY), hl

