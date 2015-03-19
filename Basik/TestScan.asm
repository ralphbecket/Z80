                emulate_spectrum "48k"
                output_szx "TestScan.szx", 0, Start
                org $8000

debug           equ true

Start           proc

                call Cls

                ld hl, testStr
                ld (NextChPtr), hl
                call PutStrNL
                call NL

lp              call Scan
                push af
                call PutTok
                pop af
                or a
                jp nz, lp

                di
                halt ; Done

                ret

                endp

testStr         db "  1 123 65535 65536 + - > >= ! != < <= & && | || "
testIDs         db "foo _bar fooBar foo_Bar foo123 foo123Bar ", 0

                include "Scan.asm"
                include "Puts.asm"
