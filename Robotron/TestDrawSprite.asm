TestDrawSprite          ld hl, PlayerBitmap
                        ld (DrawSprite_BitmapPtr), hl
                        ld a, Bright + YellowInk
                        ld (DrawSprite_Attr), a

                        ld de, $0f0f
                        call DrawSprite
                        ;ld de, $1110
                        ;call DrawSprite
                        ret

