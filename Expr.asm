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
; Values are stacked thus: [const or var][type, kind]
; where type is one of Type{Int,Ints,Str,Strs} and Kind is one
; of Kind{Con,Var,Stk,HL} -- the kind information is needed to
; generate efficient code.

Expr            ld hl, 0                ; Initialise the stack etc.
                ld (kindHLPtr), hl
                push hl                 ; Dummy [type, kind].
                push hl                 ; Dummy value.
                ld hl, doneTbl
                push hl                 ; Start of expr pseudo-op.

eReentry        nop ;proc

                call Scan
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
                jp z, eComplement
                cp '('
                jp z, eLPar
                ; ... XXX other prefix unops ...

eSyntaxError    halt

eInt            ld d, TypeInt           ; Push int constant value.
                ld e, KindCon
                push de
                push hl
                jp eCont

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
                jp eCont

eNonVarID       halt ; XXX Need to consider functions here.

eNewID          halt ; Forward var references are forbidden.

; ... XXX other consts ...

eNeg            ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, negTbl
                push hl
                jp eReentry

eNot            ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, notTbl
                push hl
                jp eReentry

eComplement     ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, complementTbl
                push hl
                jp eReentry

eLPar           ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, lparTbl
                push hl
                jp eReentry

; ... XXX other prefix unops ...

eCont           call Scan
                cp '-'
                jp z, eSub
                cp '+'
                jp z, eAdd
                cp ')'
                jp z, eRPar
                cp '='
                jp z, eEQ
                ; ... XXX other infix binops ...

                call UnScan
                ld hl, $ffff            ; Pushing this will tie the knot.
                jp pushBinOp

eSub            ld hl, subTbl
                jp pushBinOp

eAdd            ld hl, addTbl
                jp pushBinOp

eRPar           ld hl, rparTbl
                jp pushBinOp

eEQ             ld hl, eqTbl
                jp pushBinOp

; ... XXX other infix binops ...

pushBinOp       ld (newBinOp), hl

pushBinOpLp     inc sp                  ; Skip the top value and its type/kind.
                inc sp
                inc sp
                inc sp
                pop de                  ; Fetch the prev op.
                push de                 ; Restore the sp.
                dec sp
                dec sp
                dec sp
                dec sp

                ; Operators that bind less tightly have higher op table addresses.
                ; We can only stack an operator above an operator that binds less
                ; tightly.
                ; hl = new operator, de = operator atop the stack.
                ; If hl - de results in no carry, then de <= hl (de binds more
                ; tightly than hl) and we must pop and compile the de operator.
                ; If hl - de results in a carry, then hl < de (de binds less
                ; tightly than hl) and it is safe to push the new hl operator.
                and a
                sbc hl, de              ; Compare the prev and new operators.
                jp c, pushNewBinOp

                ; The prev op binds no less tightly - we must pop it and compile it.

                pop hl
                ld (binOpRValue), hl
                pop hl
                ld (binOpRTypeKind), hl
                pop de                  ; de = prev op.
                pop hl
                ld (binOpLValue), hl
                pop hl
                ld (binOpLTypeKind), hl
                ex de, hl               ; hl = prev op.

                ld a, (binOpLType)      ; Compute the (L type, R type) pair for the args.
                add a, a
                add a, a
                add a, a
                add a, a
                ld b, a
                ld a, (binOpRType)
                or b                    ; a = (Left type, right type).
                ld (cmpOpType + 1), a   ; SMC!

                ld de, 32               ; Size of an operator kind map.

searchTypeLp    ld a, (hl)              ; Search for a match for this arg type pair.
                inc hl
                inc a
                jp z, eOpTypeMatch      ; It's a generic operator!
                dec a
                jp z, eTypeError        ; We've reached the end and no match!

cmpOpType       cp 0                    ; SMC!
                jp z, eOpTypeMatch      ; That's our Hitler!

                add hl, de              ; Advance to next type pair + kind map.
                jp searchTypeLp

eOpTypeMatch    ld a, (binOpLKind)      ; Compute the (L kind, r kind) pair for the args.
                add a, a
                add a, a
                ld b, a
                ld a, (binOpRKind)
                or b

                add a, a                ; Now look up the right code to jump to.
                add a, l
                ld l, a
                adc a, h
                sub l
                ld h, a
                ld a, (hl)
                inc hl
                ld h, (hl)
                ld l, a

                ld bc, (binOpLValue)    ; bc = left value.
                ld de, (binOpRValue)    ; de = right value.

                jp (hl)                 ; And we're outta here!  The called code
                                        ; should compile the operator, push the
                                        ; resulting value record, and then jp eRetryOpPush.

eRetryOpPush    ld hl, (newBinOp)
                jp pushBinOpLp

pushNewBinOp    add hl, de              ; The prev op binds less tightly.
                push hl                 ; It's safe to just push the new op.

                jp eReentry

eDone           call UnScan             ; "UnScan" the last token.
                ld hl, doneTbl          ; Tie the knot.
                jp pushBinOp

eTypeError      halt

stealHL         ld hl, (kindHLPtr)
                ld a, h
                or l
                ret z
                ld a, KindStk
                ld (hl), a
                push de
                push bc
                ld hl, stealHLCode
                ld bc, stealHLCodeLength
                call Gen
                pop bc
                pop de
                ret

stealHLCode     push hl
stealHLCodeLength equ * - stealHLCode

pushIntResult   ld d, TypeInt           ; Given: e = kind
pushIntTyKy     push de
                ld a, KindHL
                cp e
                jp nz, pushIntValue
                ld (kindHLPtr), sp
pushIntValue    push hl
                jp eRetryOpPush

; The operator tables.  Each operator table should appear in address order from most to
; least tightly binding.  Each table is a sequence of [(left type, right type) pair, kind map]
; records (where each kind map is a set of pointers to code to implement ConCon, ConVar,
; ConStk, ConHL, VarCon, ..., HLHL value pairs), terminated by a 0 byte.

; Right now, for debugging, I'm using empty/dummy tables.

; Operators that bind less tightly have higher op table addresses.

negTbl          db $10 * TypeVoid + TypeInt
                dw negHL,  negCon,  negVar,  negStk
                dw negHL,  negCon,  negVar,  negStk
                dw negHL,  negCon,  negVar,  negStk
                dw negHL,  negCon,  negVar,  negStk
                db 0

negStk          halt ; neg kind error!

negHL           ld hl, negHLCode
                ld bc, negHLLength
                call Gen
                ld e, KindHL
                jp pushIntResult

negHLCode       ex de, hl
                ld hl, 0
                and a
                sbc hl, de
negHLLength     equ * - negHLCode

negCon          ld hl, 0
                and a
                sbc hl, de
                ld e, KindCon
                jp pushIntResult

negVar          call stealHL
                ld (negVarCode + 1), de
                ld hl, negVarCode
                ld bc, negVarLength
                call Gen
                ld e, KindHL
                jp pushIntResult

negVarCode      ld de, (00)             ; SMC!
                ld hl, 0
                and a
                sbc hl, de
negVarLength    equ * - negVarCode

addTbl          db $10 * TypeInt + TypeInt
                dw addHLHL,  addHLCon,  addHLVar,  addHLStk
                dw addConHL, addConCon, addConVar, addConStk
                dw addVarHL, addVarCon, addVarVar, addVarStk
                dw addStkHL, addStkCon, addStkVar, addStkStk
                db 0

addHLHL:
addHLStk:
addConStk:
addVarStk:
addStkCon:
addStkVar:
addStkStk:
                halt ; add kind error!

addHLCon        ld (addHLConCode + 1), de
                ld hl, addHLConCode
                ld bc, addHLConLength
                call Gen
                ld e, KindHL
                jp pushIntResult

addHLConCode    ld de, 0
                add hl, de
addHLConLength  equ * - addHLConCode

addHLVar        ld (addHLVarCode + 2), de
                ld hl, addHLVarCode
                ld bc, addHLVarLength
                call Gen
                ld e, KindHL
                jp pushIntResult

addHLVarCode    ld de, (0)
                add hl, de
addHLVarLength  equ * - addHLVarCode

addConHL        ld d, b
                ld e, c
                jp addHLCon

addConCon:      ld h, b
                ld l, c
                add hl, de
                ld e, KindCon
                jp pushIntResult

addConVar       call stealHL
                ld (addConVarCode + 1), bc
                ld (addConVarCode + 4), de
                ld hl, addConVarCode
                ld bc, addConVarLength
                call Gen
                ld e, KindHL
                jp pushIntResult

addConVarCode   ld de, 0
                ld hl, (0)
                add hl, de
addConVarLength equ * - addConVarCode

addVarHL        ld d, b
                ld e, c
                jp addHLVar

addVarCon       ex de, hl
                ld d, b
                ld e, c
                ld b, h
                ld c, l
                jp addConVar

addVarVar       call stealHL
                ld (addVarVarCode+1), bc
                ld (addVarVarCode+5), de
                ld hl, addVarVarCode
                ld bc, addVarVarLength
                call Gen
                ld e, KindHL
                jp pushIntResult

addVarVarCode   ld hl, (0)
                ld de, (0)
                add hl, de
addVarVarLength equ * - addVarVarCode

addStkHL        ld hl, addStkHLCode
                ld bc, addStkHLLength
                call Gen
                ld e, KindHL
                jp pushIntResult

addStkHLCode    pop de
                add hl, de
addStkHLLength  equ * - addStkHLCode

subTbl          db $10 * TypeInt + TypeInt
                dw subHLHL,  subHLCon,  subHLVar,  subHLStk
                dw subConHL, subConCon, subConVar, subConStk
                dw subVarHL, subVarCon, subVarVar, subVarStk
                dw subStkHL, subStkCon, subStkVar, subStkStk
                db 0

subHLHL:
subHLStk:
subConStk:
subVarStk:
subStkCon:
subStkVar:
subStkStk:
                halt ; sub kind error!

subHLCon        ld (subHLConCode + 1), de
                ld hl, subHLConCode
                ld bc, subHLConLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subHLConCode    ld de, 0
                and a
                sbc hl, de
subHLConLength  equ * - subHLConCode

subHLVar        ld (subHLVarCode + 2), de
                ld hl, subHLVarCode
                ld bc, subHLVarLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subHLVarCode    ld de, (0)
                and a
                sbc hl, de
subHLVarLength  equ * - subHLVarCode

subConHL        ld (subConHLCode + 1), bc
                ld hl, subConHLCode
                ld hl, subConHLLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subConHLCode    ld de, 0
                and a
                sbc hl, de
subConHLLength  equ * - subConHLCode

subConCon:      ld h, b
                ld l, c
                and a
                sbc hl, de
                ld e, KindCon
                jp pushIntResult

subConVar       call stealHL
                ld (subConVarCode + 1), bc
                ld (subConVarCode + 4), de
                ld hl, subConVarCode
                ld hl, subConVarLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subConVarCode   ld de, 0
                ld hl, (0)
                and a
                sbc hl, de
subConVarLength equ * - subConVarCode

subVarHL        ld (subVarHLCode + 2), bc
                ld hl, subVarHLCode
                ld bc, subVarHLLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subVarHLCode    ld de, (0)
                and a
                sbc hl, de
subVarHLLength  equ * - subVarHLCode

subVarCon       call stealHL
                ld (subVarConCode + 1), bc
                ld (subVarConCode + 5), de
                ld hl, subVarConCode
                ld hl, subVarConLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subVarConCode   ld hl, 0
                ld de, (0)
                and a
                sbc hl, de
subVarConLength equ * - subVarConCode

subVarVar       call stealHL
                ld (subVarVarCode+1), bc
                ld (subVarVarCode+5), de
                ld hl, subVarVarCode
                ld bc, subVarVarLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subVarVarCode   ld hl, (0)
                ld de, (0)
                and a
                sbc hl, de
subVarVarLength equ * - subVarVarCode

subStkHL        ld hl, subStkHLCode
                ld bc, subStkHLLength
                call Gen
                ld e, KindHL
                jp pushIntResult

subStkHLCode    pop de
                ex de, hl
                and a
                sbc hl, de
subStkHLLength  equ * - subStkHLCode

eqTbl           db $10 * TypeInt + TypeInt
                dw eqHLHL,  eqHLCon,  eqHLVar,  eqHLStk
                dw eqConHL, eqConCon, eqConVar, eqConStk
                dw eqVarHL, eqVarCon, eqVarVar, eqVarStk
                dw eqStkHL, eqStkCon, eqStkVar, eqStkStk
                db 0

eqHLHL:
eqHLStk:
eqConStk:
eqVarStk:
eqStkCon:
eqStkVar:
eqStkStk:
                halt ; eq kind error!

eqHLCon         ld (eqHLConCode + 1), de
                ld hl, eqHLConCode
                ld bc, eqHLConLength
                call Gen
                call genHLToInvBool
                ld e, KindHL
                jp pushIntResult

eqHLConCode     ld de, 0
                xor a
                sbc hl, de
eqHLConLength   equ * - eqHLConCode

eqHLVar         ld (eqHLVarCode + 2), de
                ld hl, eqHLVarCode
                ld bc, eqHLVarLength
                call Gen
                call genHLToInvBool
                ld e, KindHL
                jp pushIntResult

eqHLVarCode     ld de, (0)
                xor a
                sbc hl, de
eqHLVarLength   equ * - eqHLVarCode

eqConHL         ld d, b
                ld e, c
                jp eqHLCon

eqConCon:       ld h, b
                ld l, c
                xor a
                sbc hl, de
                call hlToInvBoolCode
                ld e, KindCon
                jp pushIntResult

eqConVar        call stealHL
                ld (eqConVarCode + 1), bc
                ld (eqConVarCode + 4), de
                ld hl, eqConVarCode
                ld bc, eqConVarLength
                call Gen
                call genHLToInvBool
                ld e, KindHL
                jp pushIntResult

eqConVarCode    ld de, 0
                ld hl, (0)
                xor a
                sbc hl, de
eqConVarLength  equ * - eqConVarCode

eqVarHL         ld d, b
                ld e, c
                jp eqHLVar

eqVarCon        ex de, hl
                ld d, b
                ld e, c
                ld b, h
                ld c, l
                jp eqConVar

eqVarVar        call stealHL
                ld (eqVarVarCode+1), bc
                ld (eqVarVarCode+5), de
                ld hl, eqVarVarCode
                ld bc, eqVarVarLength
                call Gen
                call genHLToInvBool
                ld e, KindHL
                jp pushIntResult

eqVarVarCode    ld hl, (0)
                ld de, (0)
                xor a
                sbc hl, de
eqVarVarLength  equ * - eqVarVarCode

eqStkHL         ld hl, eqStkHLCode
                ld bc, eqStkHLLength
                call Gen
                call genHLToInvBool
                ld e, KindHL
                jp pushIntResult

eqStkHLCode     pop de
                xor a
                sbc hl, de
eqStkHLLength   equ * - eqStkHLCode

hlToBoolCode    ld a, h                 ; Convert hl to 1 if non-zero.
                or l
                sub 1
                ld a, 0
                ld h, a
                adc a, a
                xor $01
                ld l, a
hlToBoolLength  equ * - hlToBoolCode
                ret                     ; So we can use the above as a routine.

genHLToBool     ld hl, hlToBoolCode
                ld bc, hlToBoolLength
                jp Gen

hlToInvBoolCode ld a, h                 ; Convert hl to 0 if non-zero, 1 otherwise.
                or l
                sub 1
                ld a, 0
                ld h, a
                adc a, a
                ld l, a
hlToInvBoolLength  equ * - hlToInvBoolCode
                ret                     ; So we can use the above as a routine.

genHLToInvBool  ld hl, hlToInvBoolCode
                ld bc, hlToInvBoolLength
                jp Gen

notTbl          db "not", 0
complementTbl   db "complement", 0
xorTbl          db "xor", 0
orTbl           db "or", 0
andTbl          db "and", 0
mulTbl          db "mul", 0
divTbl          db "div", 0
orElseTbl       db "orElse", 0
andAlsoTbl      db "andAlso", 0

lparTbl         db $ff ; Generic
                dw lparAny, lparAny, lparAny, lparAny
                dw lparAny, lparAny, lparAny, lparAny
                dw lparAny, lparAny, lparAny, lparAny
                dw lparAny, lparAny, lparAny, lparAny

lparAny         ld hl, (newBinOp) ; Check waiting operator is rpar.
                ld bc, rparTbl
                and a
                sbc hl, bc
                jp nz, lparUnmatched
lparPushTyKy    ld hl, (binOpRTypeKind)
                push hl
                ld a, l
                cp KindHL
                jp nz, lparPushValue
                ld (kindHLPtr), sp
lparPushValue   push de
                jp eCont

lparUnmatched   halt ; lpar without matching rpar.

rparTbl         db $ff ; Generic.  Don't care about the rest, it's a dummy op.

doneTbl         db $ff ; Generic.
                dw doneHL,  doneCon,  doneVar,  doneStk
                dw doneHL,  doneCon,  doneVar,  doneStk
                dw doneHL,  doneCon,  doneVar,  doneStk
                dw doneHL,  doneCon,  doneVar,  doneStk
                db 0

doneHL          ld a, (binOpRType)
                ret             ; We're done (HL)!

doneCon         ld (doneConCode + 1), de

                        push de

                ld hl, doneConCode
                ld bc, doneConLength
                call Gen

                        pop hl

                ld a, (binOpRType)
                ret             ; We're done (Con)!

doneConCode     ld hl, 0        ; SMC!
doneConLength   equ * - doneConCode

doneVar         ld (doneVarCode + 1), de
                ld hl, doneVarCode
                ld bc, doneVarLength
                call Gen
                ld a, (binOpRType)
                ret             ; We're done (Var)!

doneVarCode     ld hl, (0)      ; SMC!
doneVarLength   equ * - doneVarCode

doneStk         ld hl, doneStkCode
                ld bc, doneStkLength
                call Gen
                ld a, (binOpRType)
                ret             ; We're done (Stk)!

doneStkCode     pop hl
doneStkLength   equ * - doneStkCode

