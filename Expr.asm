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

profile = true

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

                        push hl
                        ld hl, dbgEInt
                        call PutStr
                        pop hl
                        call PutInt
                        call PutNL

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

                        ld hl, dbgEVar
                        call PutStrNL

                jp eCont

eNonVarID       halt ; XXX Need to consider functions here.

eNewID          halt ; Forward var references are forbidden.

; ... XXX other consts ...

eNeg            ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, negTbl
                push hl

                        ld hl, dbgENeg
                        call PutStr

                jp eReentry

eNot            ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, notTbl
                push hl

                        ld hl, dbgENeg
                        call PutStr

                jp eReentry

eComplement     ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, complementTbl
                push hl

                        ld hl, dbgENeg
                        call PutStr

                jp eReentry

eLPar           ld hl, 0                ; Push unop dummy value.
                push hl
                push hl
                ld hl, lparTbl
                push hl

                        ld hl, dbgELPar
                        call PutStr

                jp eReentry

; ... XXX other prefix unops ...

eCont           call Scan
                cp '-'
                jp z, eSub
                cp '+'
                jp z, eAdd
                cp ')'
                jp z, eRPar
                ; ... XXX other infix binops ...

                call UnScan

                        ld hl, dbgEReachedEnd
                        call PutStr

                ld hl, $ffff            ; Pushing this will tie the knot.
                jp pushBinOp

eSub                    ld hl, dbgESub
                        call PutStr

                ld hl, subTbl
                jp pushBinOp

eAdd                    ld hl, dbgEAdd
                        call PutStr

                ld hl, addTbl
                jp pushBinOp

eRPar                   ld hl, dbgERPar
                        call PutStr

                ld hl, rparTbl
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

                        ld hl, dbgECompilingPrevOp
                        call PutStrNL

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

                        ld hl, dbgEReachedEnd
                        call PutStrNL

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

                ;endp

KindHL          equ 0                   ; Value is "in" the HL register.
KindCon         equ 1                   ; Constant.
KindVar         equ 2                   ; Variable.
KindStk         equ 3                   ; Value is "on" the stack.

newBinOp        dw 0                    ; Temporary note of the new operator to be pushed.
kindHLPtr       dw 0                    ; 0 or the address of the KindHL entry on the stack.
binOpLValue     dw 0
binOpLTypeKind  equ *
binOpLKind      db 0
binOpLType      db 0
binOpRValue     dw 0
binOpRTypeKind  equ *
binOpRKind      db 0
binOpRType      db 0

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
addHLVarLength  equ * - addHLConCode

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
subHLVarLength  equ * - subHLConCode

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
                ld hl, (binOpRTypeKind)
                push hl
                push de
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

dbgEStartOrEnd          db "[expr start/end]", 0
dbgEReachedEnd          db "reached end of expr", 13, 0
dbgEInt                 db "push int con ", 0
dbgEVar                 db "push int var ", 0
dbgESub                 db "push binop sub", 13, 0
dbgEAdd                 db "push binop add", 13, 0
dbgELPar                db "push lpar", 13, 0
dbgERPar                db "push rpar", 13, 0
dbgENeg                 db "push unop neg", 13, 0
dbgENot                 db "push unop not", 13, 0
dbgEComplement          db "push unop complement", 13, 0
dbgEPushBinOp           db "push binop ", 0
dbgECompiling           db "compiling ", 0
dbgECompilingPrevOp     db "compiling previous op", 0

profile = false
