                emulate_spectrum "48k"
                output_szx "FillChallenge.szx", 0, Start

; Set up the screen with a little test.

                org $4000
                dg ....x.....xx....
                ds 254
                dg xxx.....x..x....
                ds 254
                dg x....xx..xxx....
                ds 254
                dg xxxxxxxxxxxx....

                org $5800
                loop $300
                        db %00000111
                lend

                org $8000

Start           ld d, 6
                ld e, 100
                call Fill
                ret

                org $9000

; Scan-line fill algorithm.
; de = xy.
Fill            ld hl, 0
                push hl         ; Push 0 sentinel to mark stack bottom.
                push de         ; Push the first stretch to start filling.

FillLp          pop de
                ld a, d
                or e
                ret z           ; We've hit the stack bottom sentinel.

                call Peek
                jr nz, FillLp   ; This is already filled in.

                ld c, 0         ; Going to use c to track above/below pixels.

ScanL           dec d
                jp m, ScanLDone ; Hit LHS.

                call Peek
                jr z, ScanL     ; Still on a blank pixel.

ScanLDone       inc d

ScanR           call Peek
                jr nz, FillLp   ; Hit filled pixel.

                ld a, (hl)
                or b
                ld (hl), a      ; Fill in this pixel.

                dec e           ; Peek above and below.
                call PeekUD
                rl c
                inc e
                inc e
                call PeekUD
                dec e
                rr c

                inc d           ; Move on to the next pixel.
                jr nz, ScanR    ; Hit RHS.
                jr FillLp       ; Haven't hit RHS.

PeekUD          jp m, PeekUDFilled
                ld a, e
                cp 192
                jr nc, PeekUDFilledx
                call Peek
                jr nz, PeekUDFilled

PeekUDBlank     bit 1, c
                set 1, c
                ret nz          ; We've already pushed a location on this stretch.

                pop hl          ; This is a new stretch above/below.  Push the location.
                push de
                jp (hl)

PeekUDFilledx   nop

PeekUDFilled    res 1, c
                ret

; From John Metcalf.
; de = xy
; --
; hl = addr, b = bit mask, NZ iff (hl) & b.
Peek            ld a, d
                and 7
                ld b, a         ; b = num px from left in byte - 1.
                ld a, e
                rra
                scf
                rra
                or a
                rra
                ld l, a
                xor e
                and 248
                xor e
                ld h, a
                ld a, l
                xor d
                and 7
                xor d
                rrca
                rrca
                rrca
                ld l, a         ; hl = display byte addr.

                ld a, %10000000
BitMaskLp       rrca
                djnz BitMaskLp
                ld b, a         ; b = bit mask.
                and (hl)        ; NZ iff (hl) & b
                ret

Size            equ $ - Fill

