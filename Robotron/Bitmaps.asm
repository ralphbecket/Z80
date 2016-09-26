PlayerBitmap            dg ..xxxxxxxxx.....
                        dg .x.........x....
                        dg .x..x...x..x....
                        dg ..xxxxxxxxx.....
                        dg ....xxxxx.......
                        dg ..xxx.x.xxx.....
                        dg .xx.x...x.xx....
                        dg .xx.x.x.x.xx....
                        dg .xx.xxxxx.xx....
                        dg ...xxx.xxx......
                        dg ...xxx.xxx......
                        dg ...xxx.xxx......

                        dg ......xxxxxxxxx.
                        dg .....x.........x
                        dg .....x..x...x..x
                        dg ......xxxxxxxxx.
                        dg ........xxxxx...
                        dg ......xxx.x.xxx.
                        dg .....xx.x...x.xx
                        dg .....xx.x.x.x.xx
                        dg .....xx.xxxxx.xx
                        dg .......xxx.xxx..
                        dg .......xxx.xxx..
                        dg .......xxx.xxx..

BulletBitmap            dg ................
                        dg ................
                        dg ................
                        dg ....xxxx........
                        dg ...xxxxxx.......
                        dg ...xx..xx.......
                        dg ...xx..xx.......
                        dg ...xxxxxx.......
                        dg ....xxxx........
                        dg ................
                        dg ................
                        dg ................

                        dg ................
                        dg ................
                        dg ................
                        dg ........xxxx....
                        dg .......xxxxxx...
                        dg .......xx..xx...
                        dg .......xx..xx...
                        dg .......xxxxxx...
                        dg ........xxxx....
                        dg ................
                        dg ................
                        dg ................

BotBitmap               dg ...xxxxxx.......
                        dg ..xx....xx......
                        dg ...xxxxxx.......
                        dg ....x..x........
                        dg xxxx....xxxx....
                        dg x..........x....
                        dg x.x......x.x....
                        dg xxx.x..x.xxx....
                        dg ...x....x.......
                        dg ..x..xx..x......
                        dg .xxxx..xxxx.....
                        dg .xxxx..xxxx.....

                        dg .......xxxxxx...
                        dg ......xx....xx..
                        dg .......xxxxxx...
                        dg ........x..x....
                        dg ....xxxx....xxxx
                        dg ....x..........x
                        dg ....x.x......x.x
                        dg ....xxx.x..x.xxx
                        dg .......x....x...
                        dg ......x..xx..x..
                        dg .....xxxx..xxxx.
                        dg .....xxxx..xxxx.

; Score digits are 2x4 pixels.

Digit0                  dg ...x..x.
Digit1                  dg .x.x.x.x
Digit2                  dg xx.xx.xx
Digit3                  dg xx.x.xxx
Digit4                  dg x.x.xx.x
Digit5                  dg xxx..xxx
Digit6                  dg xxx.xxxx
Digit7                  dg xx.x.x.x
Digit8                  dg xx..xxxx
Digit9                  dg xxxx.xxx
DigitBotLo              equ Digit0 & $ff
DigitTopLo              equ * & $ff
DigitBotHi              equ Digit0 / 256
