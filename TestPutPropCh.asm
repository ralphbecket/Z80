                emulate_spectrum "48k"
                output_szx "TestPutPropCh.szx", 0, Start
                org $8000

usePropChars    equ false

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

theQuickEtc     db "abcde fghij klkmn opqrs tuvw xyz "
                db "01234567890123456789012345678912"
                db "The quick brown fox jumps over the lazy dog.  "
                db "The Quick Brown Fox Jumps Over The Lazy Dog.  "
                db "The quick brown fox jumps over the lazy dog.  "
                ;db "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG.  "
                db "3.141592768  e^(i * pi) = -1", 0

                include "PutPropCh.asm"
                include "PropChars2.asm"

CharSet         dw PropChars
PutPropX        db 0
PutAttrPtr      dw $5800
PutAttr         db %01000111

PutNL           ld hl, (PutAttrPtr)
                inc hl
                ld (PutAttrPtr), hl
                ld a, l
                and %00011111
                jp nz PutNL
                ld (PutPropX), a
                ret

