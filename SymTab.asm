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

profile = true

; FindSym (hl = chain ptr, de = str; if flags.z then hl = cell else hl = list end ptr)
;
FindSym         proc

                ld (idPtr), de
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

                ld de, (idPtr)

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

idPtr           dw 0

                endp

ResetSymTabs    ld hl, GlobalSymTab
                ld (hl), 0
                ld de, GlobalSymTab + 1
                ld bc, 255
                ldir

ResetLocals     ld hl, LocalSymTab
                ld (hl), 0
                ld de, LocalSymTab + 1
                ld bc, 255
                ldir
                ret

profile = false

GlobalSymTab    ds 256
LocalSymTab     ds 256
