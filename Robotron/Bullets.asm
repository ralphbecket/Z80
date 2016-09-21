InitBullets             ld a, 0
                        ld (NextBulletLo), a
                        ret

MoveBullets             ld hl, BulletBitmap
                        ld (DrawSprite_BitmapPtr), hl
                        ld a, BulletAttr
                        ld (DrawSprite_Attr), a
                        ld hl, BulletTable

MB_Loop                 ld a, l
                        cp TopBulletLo
                        ret z

                        ld c, (hl)
                        inc l
                        ld b, (hl)
                        inc l
                        ld e, (hl)
                        inc l
                        ld d, (hl)
                        ld a, c
                        or b
                        jr z, MB_Next

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
MB_Next                 inc l
                        jr MB_Loop

MB_RemoveBullet         pop hl
                        call RemoveBullet
                        jr MB_Loop

RemoveBullet            dec l           ; On entry HL points to the last byte in the bullet info.
                        dec l
                        dec l
                        xor a
                        ld (hl), a
                        inc l
                        ld (hl), a
                        inc l
                        inc l
                        inc l
                        ret             ; On exit HL points to the first byte in the next bullet info.

AddBullet               ld a, b
                        add a, a
                        ld b, a
                        ld a, c
                        add a, a
                        ld c, a
                        or b
                        ret z

                        ld hl, BulletTable
AB_Loop                 ld a, l
                        cp TopBulletLo
                        ret z
                        ld a, (hl)
                        inc l
                        or (hl)
                        jr z, AB_FoundFreeBullet
                        inc l
                        inc l
                        inc l
                        jr AB_Loop

AB_FoundFreeBullet      dec l
                        ld (hl), c
                        inc l
                        ld (hl), b
                        inc l
                        ld (hl), e
                        inc l
                        ld (hl), d
                        ret

