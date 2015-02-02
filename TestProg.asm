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
                ;ld hl, testProg7: call runTest
                ;ld hl, testProg8: call runTest
                ;ld hl, testProg9: call runTest
                ;ld hl, testProg10: call runTest
                ;ld hl, testProg11: call runTest
                ;ld hl, testProg12: call runTest
                ;ld hl, testProg13: call runTest
                ;ld hl, testProg14: call runTest
                ;ld hl, testProg15: call runTest
                ;ld hl, testProg16: call runTest
                ;ld hl, testProg17: call runTest
                ;ld hl, testProg18: call runTest
                ;ld hl, testProg19: call runTest
                ;ld hl, testProg20x: call runTest
                ;ld hl, testProg21x: call runTest
                ;ld hl, testProg22x: call runTest
                ;ld hl, testProg23x: call runTest
                ;ld hl, testProg24: call runTest
                ;ld hl, testProg25: call runTest
                ld hl, testProg26: call runTest

                halt ; test complete!

runTest         ld (NextChPtr), hl
                call PutStrNL
                call StartProg
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
testProg9       db "x = 3 = 3", 0
testProg10      db "x = 3 = 4", 0
testProg11      db "x = 1 y = x = x", 0
testProg12      db "x = 1 y = (x + 1) = (x + 1)", 0
testProg13      db "x = 1 y = (x + 1) = (x + 2)", 0
testProg14      db "x = 1 y = (x + 1) = x", 0
testProg15      db "x = 1 y = x = (x + 1)", 0
testProg16      db "x = 1 if x = 1 x = 2 end", 0
testProg17      db "x = 1 if x = 3 x = 2 end", 0
testProg18      db "x = 1 if x = 3 x = 2 else x = 4 end", 0
testProg19      db "x = 1 if x = 3 x = 2 elif x = 1 x = 5 else x = 4 end", 0
testProg20x     db "elif x = 1 x = 2 end", 0
testProg21x     db "else x = 2 end", 0
testProg22x     db "end", 0
testProg23x     db "x = 0 if x = 1", 0
testProg24      db "x = 0 :lp x = x + 1 if x = 1 goto lp end x = x", 0
testProg25      db "x = 1 goto l1 x = 2 :l1 if x = 1 x = 3 end", 0
testProg26      db "x = 1 goto l1 x = 2 :l1 if x = 1 x = 3 end if x = 4 goto l1 end", 0

                include "Prog.asm"
                include "Expr.asm"
                include "Gen.asm"
                include "Scan.asm"
                include "Puts.asm"
                include "SymTab.asm"
                include "Cells.asm"
                include "Vars.asm"
                include "Consts.asm"

