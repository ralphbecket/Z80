/*****************************************************************************

This is a trivially simple symbol table implementation
in the style of Forth.

The symbol table is a sequence of entries of the following form:

    [Prev entry ptr][Length][Str ptr][... Variable-length data ...]

Something smarter involving hashing could be arranged, but for
now I'm going for simplicity.

*****************************************************************************/

; Look for the symbol just scanned by the tokeniser.
; --
; NZ-flag on success.
; HL: ptr to data section of symbol table entry - also in (SymDataPtr).
FindSym                 ld hl, (SymTabLast)
fsLoop                  ld a, h
                        or l
                        ret z           ; Z-flag: failure.

                        ld e, (hl)
                        inc hl
                        ld d, (hl)
                        inc hl
                        push de         ; Save prev ptr.
                        ld b, (hl)      ; B = length.
                        inc hl
                        ld e, (hl)
                        inc hl
                        ld d, (hl)
                        inc hl
                        ld (SymDataPtr), hl
                        ld hl, (TokStart)
                        ex de, hl       ; HL = Sym string ptr, DE = Tok string ptr.
                        ld a, (TokLength)
                        cp b
                        jr nz, fsNext   ; NZ-flag: length mismatch.

fsStrCmp                ld a, (de)
                        cp (hl)
                        jr nz, fsNext
                        inc hl
                        inc de
                        djnz fsStrCmp

fsFound                 pop de          ; Discard saved prev ptr.
                        ld hl, (SymDataPtr)
                        inc b           ; NZ-flag: success!  HL = Ptr to data section.
                        ret

fsNext                  pop hl          ; HL = prev ptr.
                        jr fsLoop


; Add the symbol just scanned by the tokeniser to the symbol table.
; --
; HL: ptr to the data section of the symbol table entry.
;
; Note: if data is added to the entry, the SymTabTop variable must be
; updated to point to the first byte after the data.
AddSym                  ld hl, (SymTabTop)
                        ld de, (SymTabLast)
                        ld (SymTabLast), hl
                        ld (hl), e: inc hl: ld (hl), d: inc hl
                        ld a, (TokLength)
                        ld (hl), a: inc hl
                        ld de, (TokStart)
                        ld (hl), e: inc hl: ld (hl), d: inc hl
                        ld (SymTabTop), hl
                        ld (SymDataPtr), hl
                        ret



SymTabTop               dw 0            ; One past the last byte in the table.
SymTabLast              dw 0            ; Ptr to the last entry in the table.
SymDataPtr              dw 0            ; Ptr to the data for the last found symbol.

