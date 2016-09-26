CheckCollisions         ld hl, BotTable
CC_BotLoop              ld a, l
                        cp TopBotLo
                        ret z

                        ld a, (hl)
                        and a
                        jr nz, CC_FoundLiveBot

CC_FoundFreeBot         inc l
                        inc l
                        inc l
                        jr CC_BotLoop

CC_FoundLiveBot         inc l
                        ld c, (hl)
                        inc l
                        ld b, (hl)
                        inc l

                        push hl
                        ld hl, BulletTable
CC_BulletLoop           ld a, l
                        cp TopBulletLo
                        jr z, CC_CheckPlayer

                        ld a, (hl)
                        inc l
                        or (hl)
                        jr nz, CC_FoundLiveBullet

CC_FoundFreeBullet      inc l
                        inc l
                        inc l
                        jr CC_BulletLoop

CC_FoundLiveBullet      inc l
                        ld e, (hl)
                        inc l
                        ld d, (hl)
                        inc l
                        call CheckCollision
                        jr nc, CC_BulletLoop

CC_FoundCollision       dec l
                        call RemoveBullet
                        pop hl
                        push hl
                        dec l
                        call RemoveRobot

                        call IncScore

                        pop hl
                        jr CC_BotLoop

CC_CheckPlayer          ld de, (PlayerXY)
                        call CheckCollision
                        jr nc, CC_NoPlayerHit

CC_PlayerHit            ld bc, PortQWERT
                        in a, (c)
                        and KeyRMask
                        jp z, Main
                        jr CC_PlayerHit

CC_NoPlayerHit          pop hl
                        jr CC_BotLoop

; Compare BC as yx against DE as y'x' for
; |y - y'| <= 2 && |x - x'| <= 2.
; Returns with carry set iff this is true.
CheckCollision          ld a, c
                        sub a, e
                        add a, 2
                        cp 5
                        ret nc
                        ld a, b
                        sub a, d
                        add a, 2
                        cp 5
                        ret
