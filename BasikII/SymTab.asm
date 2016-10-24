; This is a trivially simple symbol table implementation
; in the style of Forth.
;
; The symbol table is a sequence of entries of the following form:
;
;       [Prev entry ptr][Length][Str ptr][... Variable-length data ...]
;
; Something smarter involving hash tables could be arranged, but for
; now I'm going for simplicity.

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
                        ld (fsSymDataPtr), hl
                        ld hl, (TokStart)
                        ex de, hl       ; HL = Sym string ptr, DE = Tok string ptr.
                        ld a, (TokLen)
                        cp b
                        jr nz, fsNext   ; NZ-flag: length mismatch.

fsStrCmp                ld a, (de)
                        cp (hl)
                        jr nz, fsNext
                        inc hl
                        inc de
                        djnz fsStrCmp

fsFound                 pop de          ; Discard saved prev ptr.
                        ld hl, (fsSymDataPtr)
                        inc b           ; NZ-flag: success!  HL = Ptr to data section.
                        ret

fsNext                  pop hl          ; HL = prev ptr.
                        jr fsLoop

fsSymDataPtr            dw 0
