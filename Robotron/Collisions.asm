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
                        jr z, CC_BulletLoopDone

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
                        ld a, c
                        sub a, e
                        add a, 2
                        cp 5
                        jr nc, CC_BulletLoop
                        ld a, b
                        sub a, d
                        add a, 2
                        cp 5
                        jr nc, CC_BulletLoop

CC_FoundCollision       dec l
                        call RemoveBullet
                        pop hl
                        push hl
                        dec l
                        call RemoveRobot
                        ; XXX Increment score.
                        pop hl
                        jr CC_BotLoop

CC_BulletLoopDone       ld de, (PlayerXY)
                        ld a, c
                        sub a, e
                        add a, 2
                        cp 5
                        jr nc, CC_NoPlayerHit
                        ld a, b
                        sub a, d
                        add a, 2
                        cp 5
                        jr nc, CC_NoPlayerHit

CC_PlayerHit            ld bc, PortQWERT
                        in a, (c)
                        and KeyRMask
                        jp z, Main
                        jr CC_PlayerHit

CC_NoPlayerHit          pop hl
                        jr CC_BotLoop

