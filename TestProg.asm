                emulate_spectrum "48k"
                output_szx "TestProg.szx", 0, Start
                org $8000

debug           equ true
usePropChars    equ false

Start           call Cls
                ;ld hl, testProg0: call runTest
                ;ld hl, testProg1: call runTest
                ;ld hl, testProg2: call runTest
                ;ld hl, testProg3: call runTest
                ;ld hl, testProg4: call runTest
                ;ld hl, testProg5: call runTest
                ;ld hl, testProg6: call runTest
                ld hl, testProg7: call runTest
                ld hl, testProg8: call runTest
                ;ld hl, theQuickEtc: call PutStrNL
                halt ; test complete!

runTest         ld (NextChPtr), hl
                call PutStrNL
                call ResetProg
                call Prog
                call GenRet
                ld hl, (CodeBase)
                call runProg
                call PutInt
                call PutNL
                ret

runProg         jp (hl)

separator       db "----------------", 0
testProg0       db "x = 1 + 2", 0
testProg1       db "x = 1 y = 2", 0
testProg2       db "x = 1 y = x", 0
testProg3       db "x = 1 y = x + 1", 0
testProg4       db "x = 1 y = 2 + x", 0
testProg5       db "x = 1 y = x + 5 - 3 + x", 0
testProg6       db "x = 1 + (3 - 2)", 0
testProg7       db "x = 1 x = x + 1", 0
testProg8       db "x = 1 y = 2 x = x + y", 0

theQuickEtc     db "The Quick, Brown Fox Jumps Over The Lazy Dog.", 0

                include "Prog.asm"
                include "Expr.asm"
                include "Gen.asm"
                include "Scan.asm"
                include "Puts.asm"
                include "SymTab.asm"
                include "Cells.asm"
                include "Vars.asm"
                include "Consts.asm"

