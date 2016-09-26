InitRobots              ld hl, BotTable
                        ld de, BotTable + 1
                        ld bc, TopBotLo + 2
                        ld (hl), l      ; l = $00
                        ldir
                        ld hl, InitBotsPerWave * $100 + NewBotTimerReset
                        ld (NewBotTimer), hl

