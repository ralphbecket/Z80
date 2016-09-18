InitPlayer              ld a, PlayerTimerReset
                        ld (PlayerTimer), a
                        ld hl, $151e
                        ld (PlayerXY), hl
                        ret

MovePlayer              ld hl, PlayerTimer
                        dec (hl)
                        jr nz, DrawPlayer

                        ld (hl), PlayerTimerReset

TestKeys                ld de, 0

TestKeyUp               ld bc, PortQWERT
                        in a, (c)
                        and KeyQMask
                        jr nz, TestKeyDown
                        dec d
TestKeyDown             ld bc, PortASDFG
                        in a, (c)
                        and KeyAMask
                        jr nz, TestKeyLeft
                        inc d
TestKeyLeft             ld bc, PortPOIUY
                        in a, (c)
                        and KeyOMask
                        jr nz, TestKeyRight
                        dec e
TestKeyRight            in a, (c)
                        and KeyPMask
                        jr nz, TestKeysDone
                        inc e

TestKeysDone            push de
                        ld de, (PlayerXY)
                        call ClearSprite
                        ld de, (PlayerXY)
                        pop bc
                        call Move
                        ld (PlayerXY), de
                        call Fire

DrawPlayer              ld de, (PlayerXY)
                        ld hl, PlayerBitmap
                        ld (DrawSprite_BitmapPtr), hl
                        ld a, PlayerAttr
                        ld (DrawSprite_Attr), a
                        call DrawSprite
                        ret

