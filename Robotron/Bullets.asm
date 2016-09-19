InitBullets             ld a, 0
                        ld (NextBulletLo), a
                        ret

MoveBullets             ld hl, BulletBitmap
                        ld (DrawSprite_BitmapPtr), hl
                        ld a, BulletAttr
                        ld (DrawSprite_Attr), a
                        ld hl, BulletTable

MB_Loop                 ld a, (NextBulletLo)
                        cp l
                        ret z

                        ld c, (hl)
                        inc l
                        ld b, (hl)
                        inc l
                        ld e, (hl)
                        inc l
                        ld d, (hl)

                        push hl
                        push hl
                        push de
                        push bc
                        call ClearSprite
                        pop bc
                        pop de
                        pop hl
                        call Move
                        ld (hl), d
                        dec l
                        ld (hl), e
                        inc l
                        inc l

                        jr nc, MB_RemoveBullet
                        call DrawSprite

                        pop hl
                        inc l
                        jr MB_Loop

MB_RemoveBullet         pop hl
                        ld a, (NextBulletLo)
                        ld e, a
                        ld d, h
                        dec e
                        ex de, hl
                        ldd
                        ldd
                        ldd
                        ldd
                        ex de, hl
                        inc hl
                        ld a, e
                        inc a
                        ld (NextBulletLo), a

                        jr MB_Loop

Fire                    ld a, b
                        add a, a
                        ld b, a
                        ld a, c
                        add a, a
                        ld c, a
                        or b
                        ret z

                        ld a, (NextBulletLo)
                        cp TopBulletLo
                        ret z

                        ld l, a
                        ld h, BulletTableHi
                        ld (hl), c
                        inc l
                        ld (hl), b
                        inc l
                        ld (hl), e
                        inc l
                        ld (hl), d
                        inc l
                        ld a, l
                        ld (NextBulletLo), a
                        ret

