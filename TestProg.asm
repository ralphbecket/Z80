                emulate_spectrum "48k"
                output_szx "TestProg.szx", 0, Start
                org $8000

                ;profile = true

debug           equ false
usePropChars    equ true

Start           call Cls
                ld hl, testProg0: call runTest
                ld hl, testProg1: call runTest
                ld hl, testProg2: call runTest
                ld hl, testProg3: call runTest
                ld hl, testProg4: call runTest
                ld hl, testProg5: call runTest
                ld hl, testProg6: call runTest
                ld hl, testProg7: call runTest
                ld hl, testProg8: call runTest
                ld hl, testProg9: call runTest
                ld hl, testProg10: call runTest
                ld hl, testProg11: call runTest
                ld hl, testProg12: call runTest
                ld hl, testProg13: call runTest
                ld hl, testProg14: call runTest
                ld hl, testProg15: call runTest
                ld hl, testProg16: call runTest
                ld hl, testProg17: call runTest
                ld hl, testProg18: call runTest
                ld hl, testProg19: call runTest
                ;ld hl, testProg20x: call runTest
                ;ld hl, testProg21x: call runTest
                ;ld hl, testProg22x: call runTest
                ;ld hl, testProg23x: call runTest
                ld hl, testProg24: call runTest
                ld hl, testProg25: call runTest
                ld hl, testProg26: call runTest
                ld hl, testProg27: call runTest
                ld hl, testProg28: call runTest
                ld hl, testProg29: call runTest
                ld hl, testProg30: call runTest
                ld hl, testProg31: call runTest
                ld hl, testProg32: call runTest
                ld hl, testProg33: call runTest
                ld hl, testProg34: call runTest
                ld hl, testProg35: call runTest
                ld hl, testProg36: call runTest
                ld hl, testProg37: call runTest
                ld hl, testProg38: call runTest
                ld hl, testProg39: call runTest
                ld hl, testProg40: call runTest
                ld hl, testProg41: call runTest
                ld hl, testProg42: call runTest
                ld hl, testProg43: call runTest
                ld hl, testProg44: call runTest
                ld hl, testProg45: call runTest
                ld hl, testProg46: call runTest
                ld hl, testProg47: call runTest
                ld hl, testProg48: call runTest
                ld hl, testProg49: call runTest
                ld hl, testProg50: call runTest

                halt ; test complete!

runTest         ld (NextChPtr), hl
                call PutStrNL
                call CompileProg
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
testProg27      db "goto l3 :l1 goto l2 :l3 goto l1 :l2", 0
testProg28      db "x = 5 != 6", 0
testProg29      db "x = 7 != 7", 0
testProg30      db "x = 2 & 3", 0
testProg31      db "x = 2 | 1", 0
testProg32      db "x = 1 < 2", 0
testProg33      db "x = 1 < 1", 0
testProg34      db "x = 2 < 1", 0
testProg35      db "x = 1 > 2", 0
testProg36      db "x = 1 > 1", 0
testProg37      db "x = 2 > 1", 0
testProg38      db "x = 1 <= 2", 0
testProg39      db "x = 1 <= 1", 0
testProg40      db "x = 2 <= 1", 0
testProg41      db "x = 1 >= 2", 0
testProg42      db "x = 1 >= 1", 0
testProg43      db "x = 2 >= 1", 0
testProg44      db "x = 0 && 10", 0
testProg45      db "x = 10 && 0", 0
testProg46      db "x = 10 && 20", 0
testProg47      db "x = 0 || 10", 0
testProg48      db "x = 10 || 0", 0
testProg49      db "x = 10 || 20", 0
testProg50      db "x = 10 y = -x", 0

                include "Prog.asm"
                include "Expr.asm"
                include "Gen.asm"
                include "Scan.asm"
                include "SymTab.asm"
                include "Cells.asm"
                include "Vars.asm"
                include "Consts.asm"
                include "Puts.asm"

