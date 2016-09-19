InitRobots                ld hl, BotTable
                        ld de, BotTable + 1
                        ld bc, TopBotLo + 2
                        ld (hl), l      ; l = $00
                        ldir
                        ret

MoveRobots              ld hl, BotBitmap
                        ld (DrawSprite_BitmapPtr), hl
                        ld a, BotAttr
                        ld (DrawSprite_Attr), a
                        ld a, (PlayerXY)
                        ld (MR_CmpPlayerX), a
                        ld a, (PlayerXY + 1)
                        ld (MR_CmpPlayerY), a
                        ld hl, BotTable

MR_Loop                 ld a, l
                        cp TopBotLo
                        ret nc

                        ld a, (hl)
                        and a
                        jr nz, MR_UpdateBot
                        inc l
                        inc l
                        inc l
                        jr MR_Loop

MR_UpdateBot            dec (hl)
                        jr z, MR_MoveBot
                        inc l
                        ld e, (hl)
                        inc l
                        ld d, (hl)
                        jr MR_DrawBot

MR_MoveBot              ld (hl), BotTimerReset
                        inc l

MR_ClearBot             ld e, (hl)
                        inc l
                        ld d, (hl)

                        push hl
                        push de
                        call ClearSprite
                        pop de
                        pop hl

                        call Rnd
                        rrca
                        jr c, MR_UpOrDown

MR_LeftOrRight          ld a, e
                        cp 0
MR_CmpPlayerX           equ * - 1
                        jr z, MR_UpOrDown
MR_Down                 inc e
                        jr c, MR_DrawBot
MR_Up                   dec e
                        dec e
                        jr MR_DrawBot

MR_UpOrDown             ld a, d
                        cp 0
MR_CmpPlayerY           equ * - 1
                        jr z, MR_DrawBot
MR_Right                inc d
                        jr c, MR_DrawBot
MR_Left                 dec d
                        dec d

MR_DrawBot              ld (hl), d
                        dec l
                        ld (hl), e
                        inc l
                        inc l
                        push hl
                        call DrawSprite
                        pop hl
                        jr MR_Loop

