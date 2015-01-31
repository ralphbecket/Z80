; Symbol Table
;
; The symbol table is implemented as a 128-entry hash table.
; Each symbol is represented as follows:
; - a two-byte pointer to the identifier in the source code;
; - a one-byte type indicator;
; - a two-byte data field;
; - a two-byte pointer to the next cell in the chain (or 0).
; Looking up an identifier returns either the existing cell
; for that identifier (in fact, the pointer to the type field)
; or the pointer to the field which should be filled in with
; the new cell, should one be allocated.

; FindSym (hl = symtab ptr, de = str; if flags.z then hl = cell else hl = list end ptr, abcde = xxxxx)
;
FindSym         ld (symTabIDPtr), de
                ex de, hl

                xor a                   ; Compute the str hash.
hashLp          ld b, (hl)
                inc b
                dec b
                jp z, findChain
                inc hl
                rrca
                rrca
                rrca
                xor b
                jp hashLp

findChain       ex de, hl               ; Find the hash table chain.
                add a, a
                add a, l
                ld l, a
                adc a, h
                sub l
                ld h, a                 ; hl = cell ptr ptr.

searchChainLp   ld e, (hl)
                inc hl
                ld d, (hl)              ; de = cell ptr.
                dec hl
                ld a, d
                or e
                jp z, notFound

                ld a, (de)
                ld l, a
                inc de
                ld a, (de)
                inc de                  ; de = type field ptr.
                ld h, a                 ; hl = src id ptr.

                push de                 ; Push type field ptr.

                ld de, (symTabIDPtr)

cmpStr          ld a, (de)
                or a
                jp z, found
                sub (hl)
                jp nz, tryNext
                inc de
                inc hl
                jp cmpStr

tryNext         pop hl                  ; hl = type field ptr.
                inc hl                  ; Skip type field.
                inc hl                  ; Skip data field.
                inc hl
                jp searchChainLp

found           pop hl                  ; hl = type field ptr.
                xor a
                ret                     ; z for success.

notFound        inc a                   ; hl = null cell ptr ptr.
                ret                     ; nz for failure.

; AddEntry (hl = ptr to fill in with new cell, bc = ptr to ID, a = type, de = data; abcdehl = xxxxxxx).
;
AddEntry        push de
                push af
                push bc
                push hl
                call Alloc
                ex de, hl
                pop hl
                ld (hl), e              ; Fill in ptr to new cell.
                inc hl
                ld (hl), d
                ex de, hl
                pop bc
                ld (hl), c              ; Fill in id ptr field.
                inc hl
                ld (hl), b
                inc hl
                pop af
                ld (hl), a              ; Fill in type field.
                inc hl
                pop de
                ld (hl), e              ; Fill in data field.
                inc hl
                ld (hl), d
                inc hl
                xor a
                ld (hl), a              ; Zero next cell ptr field.
                inc hl
                ld (hl), a
                ret

ResetSymTabs    ld hl, GlobalSymTab     ; XXX Should free entries from symtab.
                ld (hl), 0
                ld de, GlobalSymTab + 1
                ld bc, 255
                ldir

                ; Add the keywords to the global symtab.

                ld de, KwIf
                ld a, TokIf
                call addKw
                ld de, KwEnd
                ld a, TokEnd
                call addKw
                ld de, KwGoto
                ld a, TokGoto
                call addKw
                ld de, KwElse
                ld a, TokElse
                call addKw
                ld de, KwElif
                ld a, TokElif
                call addKw
                ld de, KwFun
                ld a, TokFun
                call addKw
                ld de, KwRet
                ld a, TokRet
                call addKw
                ld de, KwInt
                ld a, TypeInt
                call addKw
                ld de, KwInts
                ld a, TypeInts
                call addKw
                ld de, KwStr
                ld a, TypeStr
                call addKw
                ld de, KwStrs
                ld a, TypeStrs
                call addKw

ResetLocals     ld hl, LocalSymTab      ; XXX Should free entries from symtab.
                ld (hl), 0
                ld de, LocalSymTab + 1
                ld bc, 255
                ldir
                ret

addKw           ld hl, GlobalSymTab
                push de
                push af
                call FindSym
                pop af
                pop bc
                ld de, 0
                jp AddEntry


