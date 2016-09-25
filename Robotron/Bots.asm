InitRobots              ld hl, BotTable
                        ld de, BotTable + 1
                        ld bc, TopBotLo + 2
                        ld (hl), l      ; l = $00
                        ldir
                        ld hl, InitBotsPerWave * $100 + NewBotTimerReset
                        ld (NewBotTimer), hl
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

AddNewRobots            ld hl, (NewBotTimer)
                        dec l
                        ld (NewBotTimer), hl
                        ret nz
                        inc h                   ; Inc. bots per wave.
                        ld l, NewBotTimerReset
                        ld (NewBotTimer), hl

                        ld b, h
AN_Loop                 push bc
                        call AddNewRobot
                        pop bc
                        djnz AN_Loop
                        ret

AddNewRobot             call Rnd
                        rrca
                        jr c, AR_TopOrBot
AR_LeftOrRight          rrca
                        jr c, AR_Right
AR_Left                 ld e, 0
                        jr AR_BoundY
AR_Right                ld e, 61
AR_BoundY               and 63
                        ld d, a
                        cp 46
                        jr c, AR_FindFreeBot
                        sub a, 32
                        ld d, a
                        jr AR_FindFreeBot
AR_TopOrBot             rrca
                        ld e, a
                        rrca
                        jr c, AR_Bot
AR_Top                  ld d, 0
                        jr AR_BoundX
AR_Bot                  ld d, 45
AR_BoundX               and 60
                        ld e, a
AR_FindFreeBot          ld hl, BotTable
                        ld b, MaxBots
AR_Loop                 ld a, (hl)
                        and a
                        jr z, AR_FoundFreeBot
                        inc l
                        inc l
                        inc l
                        djnz AR_Loop
                        ret
AR_FoundFreeBot         ld (hl), BotTimerReset
                        inc l
                        ld (hl), e
                        inc l
                        ld (hl), d
                        ret

; On entry, HL points to last byte of bot info.
RemoveRobot             ld d, (hl)
                        dec l
                        ld e, (hl)
                        dec l
                        ld (hl), 0
                        call ClearSprite
                        ret
