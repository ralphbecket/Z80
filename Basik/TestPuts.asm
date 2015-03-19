                emulate_spectrum "48k"
                output_szx "TestPuts.szx", 0, Start
                org $8000

Start           call Cls
                ld hl, 1234
                call PutInt
                call PutNL
                ld hl, -1234
                call PutInt
                call PutNL
                ld hl, 65432
                call PutUInt
                call PutNL
                ld a, $00
                call PutHexByte
                call PutSpc
                ld a, $a8
                call PutHexByte
                call PutSpc
                ld a, $ff
                call PutHexByte
                call PutSpc
                ld hl, $beef
                call PutHexWord
                call PutNL
                loop 20
                ld hl, PutAttr
                inc (hl)
                ld hl, Hello
                call PutStr
                ld hl, World
                call PutStr
                ;call NL
                ;call Scroll
                lend
                ld hl, PutAttr
                ld (hl), WhitePaper + BlackInk
                jp Start
                halt

                AlignmentGap(16)
Hello           db "Hello ", 0
World           db "World!", 13, 0

                include "Puts.asm"
