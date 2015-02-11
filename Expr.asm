; The general pattern of expressions is...
;
; Expr ::= ((Unop|LPar)*(Const|Var|Func))[Binop Expr|RPar]
;
; Unop ::= -|!|~
;
; Binop ::= +|-|*|/|&|||^|&&||||=|!=|<|<=|>|>=
;
; We store information on the stack thus:
;
;       [value][op][value][op][value]...[eStart]
;
; An operator A can only be stacked if the preceding operator B
; binds less tightly.  If not, the preceding operator B is
; unstacked and has code generated, then another attempt is made
; to stack operator A.
;
; Operators are stacked as [op precedence, op index] with
; op precedence being in the upper byte.  A lower precedence
; indicates tighter binding.  The op index indicates the first
; entry in the op table for this operator.
;
; The op table is a sequence of entries of the following form:
; - 1/2                 unop/binop;
; - types               types for the arguments (l/r in hi/lo nybbles);
; - 0/1                 last entry for op/op has more entries;
; - special handler/0   ptr to any special handler code;
; - code                ptr to code implementing op (l/r in de/hl);
; - code length         byte length of code implementing op;
; - result type         byte code for result type.
;
; Values are stacked thus: [const or var][type, kind]
; where type is one of Type{Int,Ints,Str,Strs} and Kind is one
; of Kind{Con,Var,Stk,HL} -- the kind information is needed to
; generate efficient code.

Expr            ld hl, 0
                ld (eKindHLPtr), hl     ; Reset this variable.
                ld hl, $ff00 + eDoneIdx ; Initialise the op/value stack.
                push hl                 ; Start of expr pseudo-op.

eExpUnopOrValue call Scan
                cp TokInt
                jp z, eInt
                cp TokID
                jp z, eID
                cp TokNewID
                jp z, eNewID
                ; ... XXX other consts ...
                cp '-'
                jp z, eNeg
                cp '!'
                jp z, eNot
                cp '~'
                jp z, eCpl
                cp '('
                jp z, eLPar
                ; ... XXX other prefix unops ...

                ld hl, $0000
                jp ePushBinOp           ; Tie the knot.

eInt            ld d, TypeInt           ; Push int constant value.
                ld e, KindCon
                push de
                push hl
                jp eExpBinOpOrDone

eID             ld a, (hl)
                and NonTypeBits
                jp nz, eNonVarID

                ld e, KindVar
                ld d, (hl)
                push de
                inc hl
                ld e, (hl)
                inc hl
                ld d, (hl)
                push de
                jp eExpBinOpOrDone

eNonVarID       halt ; XXX Need to consider functions here.

eNewID          halt ; Forward var references are forbidden.

; ... XXX other consts ...

eNeg            ld hl, $0000 + eNegIdx
                push hl
                jp eExpUnopOrValue

eNot            ld hl, $0000 + eNotIdx
                push hl
                jp eExpUnopOrValue

eCpl            ld hl, $0000 + eCplIdx
                push hl
                jp eExpUnopOrValue

eLPar           ld hl, $ff00 + eLParIdx
                push hl
                jp eExpUnopOrValue

; ... XXX other prefix unops ...

eExpBinOpOrDone call Scan
                cp '+'
                ld hl, $9000 + eAddIdx
                jp z, ePushBinOp
                cp '-'
                ld hl, $9000 + eSubIdx
                jp z, ePushBinOp
                cp ')'
                ld hl, $ff00 + eRParIdx
                jp z, ePushBinOp
                cp '='
                ld hl, $bf00 + eEQIdx
                jp z, ePushBinOp
                cp TokNE
                ld hl, $be00 + eNEIdx
                jp z, ePushBinOp
                cp '<'
                ld hl, $bd00 + eLTIdx
                jp z, ePushBinOp
                cp TokLE
                ld hl, $bd00 + eLEIdx
                jp z, ePushBinOp
                cp '>'
                ld hl, $bd00 + eGTIdx
                jp z, ePushBinOp
                cp TokGE
                ld hl, $bd00 + eGEIdx
                jp z, ePushBinOp
                cp '&'
                ld hl, $8000 + eAndIdx
                jp z, ePushBinOp
                cp '|'
                ld hl, $8000 + eOrIdx
                jp z, ePushBinOp
                ; ... XXX other infix binops ...

                call UnScan             ; This is the end of the expr.
                ld hl, $ffff            ; Pushing this will tie the knot.

ePushBinOp      ld (eNewBinOp), hl
                ld a, h                 ; a = new op precedence.

ePushBinOpLp    pop bc                  ; Skip the top value and its type/kind.
                pop de
                pop hl                  ; h/l = prev op precedence/index.
                push hl                 ; Restore the sp.
                push de
                push bc

                cp h                    ; Compare prev op precedence.
                jp c, ePushNewBinOp     ; If prev precedence is greater, then push.

                ; [Compile the prev op.]
                ; The prev op binds at least as tightly as the new op.
                ; We must compile the prev op and then try pushing the
                ; new op again.

                pop hl                  ; Fetch the right value and type/kind.
                ld (eRValue), hl
                pop hl
                ld (eRTypeKind), hl
                pop hl                  ; h/l = prev op precedence/index.

                ld h, 0
                ld a, l
                add a, a
                add a, a
                add a, a
                add a, l                ; a = 9 * op idx.
                ld l, a
                ld de, eOpTbl
                add hl, de              ; hl = op table entry ptr for prev op.

                ld a, (hl)              ; a = 1/2 for unop/binop.
                ld (eOpTblEntryPtr), hl ; Save ptr to prev-op op table entry.
                dec a
                jp nz, eBinopKinds

eUnopKind       ld a, 0
                ld (eLType), a          ; Zero the left arg type for type matching.
                ld a, (eRKind)          ; Gen code to put the arg in hl (unless con).
                ld (eLRKinds), a
                cp KindVar
                jp nz, eFindOpType

                call eStealHL
                jp eFindOpType

eBinopKinds     pop hl                  ; Fetch the left value and type/kind.
                ld (eLValue), hl
                pop hl
                ld (eLTypeKind), hl

                ld a, (eLKind)          ; Gen code to put the l/r args in de/hl (unless cons).
                add a, a
                add a, a
                add a, a
                add a, a
                ld b, a
                ld a, (eRKind)
                or b                    ; a = LKind:RKind.
                ld (eLRKinds), a

                cp $10 * KindCon + KindCon
                jp z, eFindOpType

                cp $10 * KindHL + KindCon
                jp z, eHLCon
                cp $10 * KindHL + KindVar
                jp z, eHLVar
                cp $10 * KindCon + KindHL
                jp z, eConHL
                cp $10 * KindVar + KindHL
                jp z, eVarHL
                cp $10 * KindStk + KindHL
                jp z, eStkHL

                call eStealHL
                ld a, (eLRKinds)

                cp $10 * KindCon + KindVar
                jp z, eConVar
                cp $10 * KindVar + KindVar
                jp z, eVarVar
                cp $10 * KindVar + KindCon
                jp z, eVarCon
                cp $10 * KindStk + KindHL
                jp z, eStkHL

                halt ; Kind error!  Shouldn't reach here.

eHLCon          ld hl, (eRValue)
                ld (eLdDEConExCode + 1), hl
                ld hl, eLdDEConExCode
                ld bc, eLdDEConExLength
                jp eGenBinOpKindCode

eHLVar          ld hl, (eRValue)
                ld (eLdDEVarExCode + 2), hl
                ld hl, eLdDEVarExCode
                ld bc, eLdDEVarExLength
                jp eGenBinOpKindCode

eConHL          ld hl, (eLValue)
                ld (eLdDEConCode + 1), hl
                ld hl, eLdDEConCode
                ld bc, eLdDEConLength
                jp eGenBinOpKindCode

eVarHL          ld hl, (eLValue)
                ld (eLdDEVarCode + 2), hl
                ld hl, eLdDEVarCode
                ld bc, eLdDEVarLength
                jp eGenBinOpKindCode

eStkHL          ld hl, ePopDECode
                ld bc, ePopDELength
                jp eGenBinOpKindCode

eConVar         ld hl, (eLValue)
                ld (eLdDEConHLVarCode + 1), hl
                ld hl, (eRValue)
                ld (eLdDEConHLVarCode + 4), hl
                ld hl, eLdDEConHLVarCode
                ld bc, eLdDEConHLVarLength
                jp eGenBinOpKindCode

eVarVar         ld hl, (eLValue)
                ld (eLdDEVarHLVarCode + 2), hl
                ld hl, (eRValue)
                ld (eLdDEVarHLVarCode + 5), hl
                ld hl, eLdDEVarHLVarCode
                ld bc, eLdDEVarHLVarLength
                jp eGenBinOpKindCode

eVarCon         ld hl, (eLValue)
                ld (eLdDEVarHLConCode + 2), hl
                ld hl, (eRValue)
                ld (eLdDEVarHLConCode + 5), hl
                ld hl, eLdDEVarHLConCode
                ld bc, eLdDEVarHLConLength
                jp eGenBinOpKindCode

ePopDECode      pop de
ePopDELength    equ * - ePopDECode

eLdDEVarExCode  equ *
eLdDEVarCode    ld de, (0)
eLdDEVarLength  equ * - eLdDEVarCode
                ex de, hl
eLdDEVarExLength equ * - eLdDEVarExCode

eLdDEConExCode  equ *
eLdDEConCode    ld de, 0
eLdDEConLength  equ * - eLdDEConCode
                ex de, hl
eLdDEConExLength equ * - eLdDEConExCode

eLdHLVarCode    ld hl, (0)
eLdHLVarLength  equ * - eLdHLVarCode

eLdHLConCode    ld hl, 0
eLdHLConLength  equ * - eLdHLConCode

eLdDEConHLVarCode       ld de, 0
                        ld hl, (0)
eLdDEConHLVarLength     equ * - eLdDEConHLVarCode

eLdDEVarHLVarCode       ld de, (0)
                        ld hl, (0)
eLdDEVarHLVarLength     equ * - eLdDEVarHLVarCode

eLdDEVarHLConCode       ld de, (0)
                        ld hl, 0
eLdDEVarHLConLength     equ * - eLdDEVarHLConCode

ePopHLCode              pop hl
ePopHLLength            equ * - ePopHLCode

eGenBinOpKindCode call Gen

eFindOpType     ld a, (eLType)          ; Will be zero for unops.
                add a, a
                add a, a
                add a, a
                add a, a
                ld b, a
                ld a, (eRType)
                or b                    ; a = LType:RType.
                ld (eCmpOpType + 1), a  ; SMC!

                ld hl, (eOpTblEntryPtr)
                inc hl
                ld de, eOpTblEntrySize - 1

eFindOpTypeLp   ld a, (hl)
                inc hl

eCmpOpType      cp 0                    ; SMC!
                jp z, eFoundOpType
                inc a
                jp z, eFoundOpType      ; Type $ff means it's generic.

                ld a, (hl)              ; See if there's another type entry for this op.
                add hl, de
                and a
                jp nz, eFindOpTypeLp

                halt ; Op type error!

eFoundOpType    inc hl
                ld e, (hl)
                inc hl
                ld d, (hl)
                inc hl
                ld (eOpTblEntryPtr), hl
                ex de, hl

                jp (hl)                 ; Call the special handler.  Should jp back to...

eGenOpCode      ld hl, (eOpTblEntryPtr)
                ld e, (hl)
                inc hl
                ld d, (hl)              ; de = op code ptr.
                inc hl
                ld b, 0
                ld c, (hl)              ; bc = op code length.
                inc hl

                ld a, (eLRKinds)
                and a
                ld a, (hl)              ; a = op return type.
                push af
                jp nz, eNotConOp

eConOp          ld (eCallConOp + 1), de ; SMC!
                ld de, (eLValue)
                ld hl, (eRValue)
eCallConOp      call 0

ePushConResult  pop af
                ld d, a                 ; d = result type, hl = value.
                ld e, KindCon
                push de
                push hl
                jp eRetryPushBinOp

eNotConOp       ex de, hl
                call Gen

ePushHLResult   pop af
                ld d, a                 ; d = result type.
                ld e, KindHL
                ld hl, 0
                push de
                ld (eKindHLPtr), sp
                push hl

eRetryPushBinOp ld a, (eNewBinOpPrec)   ; Retrieve the new op precedence.
                jp ePushBinOpLp         ; Try to push it again.

ePushNewBinOp   ld hl, (eNewBinOp)
                push hl
                jp eExpUnopOrValue

eStealHL        ld hl, (eKindHLPtr)
                ld a, h
                or l
                ret z
                ld a, KindStk
                ld (hl), a
                ld hl, ePushHLCode
                ld bc, ePushHLLength
                jp Gen

ePushHLCode     push hl
ePushHLLength   equ * - ePushHLCode

eNoHandler      jp eGenOpCode

; The op table is a sequence of entries of the following form:
; - 1/2                 unop/binop;
; - types               types for the arguments (l/r in hi/lo nybbles);
; - 0/1                 last entry for op/op has more entries;
; - special handler/0   ptr to any special handler code;
; - code                ptr to code implementing op (l/r in de/hl);
; - code length         byte length of code implementing op;
; - result type         byte code for result type.

eOpTblEntry     macro (arity, types, hasMore, special, code, codeLen, resultType)
                db arity
                db types
                db hasMore
                dw special
                dw code
                db codeLen
                db resultType
                endm
eOpTblEntrySize equ 9

eOpTbl          equ *

eNegIdx         equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(1, TypeInt, 0, eNoHandler, eNegCode, eNegLength, TypeInt)

eCplIdx         equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(1, TypeInt, 0, eNoHandler, eCplCode, eCplLength, TypeInt)

eNotIdx         equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(1, TypeInt, 0, eNoHandler, eNotCode, eNotLength, TypeInt)

eLParIdx        equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(1, TypeAny, 0, eLParHandler, 0, 0, 0)

eAddIdx         equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eAddCode, eAddLength, TypeInt)

eSubIdx         equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eSubCode, eSubLength, TypeInt)

eAndIdx         equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eAndCode, eAndLength, TypeInt)

eOrIdx          equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eOrCode, eOrLength, TypeInt)

eEQIdx          equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eEQCode, eEQLength, TypeInt)

eNEIdx          equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eNECode, eNELength, TypeInt)

eLTIdx          equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eLTCode, eLTLength, TypeInt)

eLEIdx          equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eLECode, eLELength, TypeInt)

eGTIdx          equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eGTCode, eGTLength, TypeInt)

eGEIdx          equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(2, $11 * TypeInt, 0, eNoHandler, eGECode, eGELength, TypeInt)

eRParIdx        equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(0, 0, 0, 0, 0, 0, 0)

eDoneIdx        equ ($ - eOpTbl) / eOpTblEntrySize
                eOpTblEntry(1, TypeAny, 0, eDoneHandler, 0, 0, 0)

eLParHandler    ld a, (eNewBinOpIdx)
                cp eRParIdx
                jp nz, eUnmatchedLPar
                ld de, (eRTypeKind)
                ld hl, (eRValue)
                push de
                ld a, KindHL
                cp e
                jp nz, eLParHandler1
                ld (eKindHLPtr), sp
eLParHandler1   push hl
                jp eExpBinOpOrDone

eUnmatchedLPar  halt

eDoneHandler    call UnScan             ; Don't consume this token.

                ld a, (eRKind)

                cp KindHL
                jp z, eDoneHL

                cp KindCon
                jp z, eDoneCon

                cp KindVar
                jp z, eDoneVar

                cp KindStk
                jp z, eDoneStk

                halt ; eDone kind error!  Should be unreachable.

eDoneHL         ld a, (eRType)
                ret

eDoneCon        ld hl, (eRValue)
                ld (eLdHLConCode + 1), hl
                ld hl, eLdHLConCode
                ld bc, eLdHLConLength
                ld a, (eRType)
                jp Gen

eDoneVar        ld hl, (eRValue)
                ld (eLdHLVarCode + 1), hl
                ld hl, eLdHLVarCode
                ld bc, eLdHLVarLength
                ld a, (eRType)
                jp Gen

eDoneStk        ld hl, ePopHLCode
                ld bc, ePopHLLength
                ld a, (eRType)
                jp Gen


eNegCode        ex de, hl
                ld hl, 0
                xor a
                sbc hl, de
eNegLength      equ * - eNegCode
                ret

eCplCode        ld a, h
                cpl
                ld h, a
                ld a, l
                cpl
                ld l, a
eCplLength      equ * - eCplCode
                ret

eNotCode        ld a, h
                or l
                ld hl, 0
                jr nz, eNotCodeL
                inc l
eNotCodeL:
eNotLength      equ * - eNotCode
                ret

eAddCode        add hl, de
eAddLength      equ * - eAddCode
                ret

eSubCode        ex de, hl
                xor a
                sbc hl, de
eSubLength      equ * - eAddCode
                ret

eEQCode         xor a
                sbc hl, de
                ld h, a
                ld l, a
                jr nz, eEQCodeL
                inc l
eEQCodeL:
eEQLength       equ * - eEQCode
                ret

eNECode         xor a
                sbc hl, de
                ld h, a
                ld l, a
                jr z, eNECodeL
                inc l
eNECodeL:
eNELength       equ * - eNECode
                ret

eAndCode        ld a, h
                and d
                ld h, a
                ld a, l
                and e
                ld l, a
eAndLength      equ * - eAndCode
                ret

eOrCode         ld a, h
                or d
                ld h, a
                ld a, l
                or e
                ld l, a
eOrLength       equ * - eOrCode
                ret

eLTCode         ex de, hl
eGTCode         xor a
                sbc hl, de
                ld h, a
                ld l, a
                jr nc, eGTCodeL
                inc l
eGTCodeL:
eGTLength       equ * - eGTCode
eLTLength       equ * - eLTCode
                ret

eGECode         ex de, hl
eLECode         xor a
                sbc hl, de
                ld h, a
                ld l, a
                jr c, eGECodeL
                inc l
eGECodeL:
eGELength       equ * - eGECode
eLELength       equ * - eLECode
                ret


