                emulate_spectrum "48k"
                output_szx "TestPutPropCh.szx", 0, Start
                org $8000

Start           ld hl, theQuickEtc
                call PutStr
                ld hl, theQuickEtc
                call PutStr
                halt

PutStr          ld a, (hl)
                and a
                ret z
                inc hl
                push hl
                call PutPropCh
                pop hl
                jp PutStr

theQuickEtc     db "The quick brown fox jumps over the lazy dog.  "
                db "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG.  "
                db "3.141592768  e^(i * pi) = -1", 0

                include "PutPropCh.asm"

