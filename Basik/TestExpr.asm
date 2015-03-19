                emulate_spectrum "48k"
                output_szx "TestExpr.szx", 0, Start
                org $8000

debug           equ true

Start           call Cls
                ld hl, testExpr8: call runTest
                ld hl, testExpr7: call runTest
                ld hl, testExpr6: call runTest
                ld hl, testExpr5: call runTest
                ;ld hl, testExpr4: call runTest
                ;ld hl, testExpr3: call runTest
                ;ld hl, testExpr2: call runTest
                ;ld hl, testExpr1: call runTest
                ;ld hl, testExpr0: call runTest
                halt ; test complete!

runTest         ld (NextChPtr), hl
                push hl
                call PutNL: ld hl, separator: call PutStrNL
                pop hl: call PutStrNL: ld hl, separator: call PutStrNL
                call Expr
                call PutInt
                call PutNL
                ret

separator       db "----------------", 0
testExpr0       db "69", 0
testExpr1       db " -123 ", 0
testExpr2       db "42 + 69", 0
testExpr3       db "1 + 2 + 3", 0
testExpr4       db "1 + -2", 0
testExpr5       db "-1 + 2", 0
testExpr6       db "1 - 2", 0
testExpr7       db "1 - -2", 0
testExpr8       db "1 + 2 - 3 + 4", 0

                include "Prog.asm"
                include "Expr.asm"
                include "Gen.asm"
                include "Scan.asm"
                include "Puts.asm"
                include "SymTab.asm"
                include "Cells.asm"

