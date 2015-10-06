; Ralph Becket's ZX Spectrum Fill Challenge.
; 106 bytes with no meaningful optimization attempts.

                emulate_spectrum "48k"
                output_szx "FillChallenge.szx", 0, Start

; Set up the screen with a little test.

                org $4000 : dg ...x................x...
                org $4100 : dg .xx....xxxx..xxxx....xx.
                org $4200 : dg .x....................x.
                org $4300 : dg .x....xxxx....xxxx....x.
                org $4400 : dg x....x....x..x....x....x
                org $4500 : dg .....x..xxx..x..xxx....x
                org $4600 : dg .....x..xxx..x..xxx....x
                org $4700 : dg ......xxxxx...xxxxx....x
                org $4020 : dg x.....................x.
                org $4120 : dg .x.........xx.........x.
                org $4220 : dg .x...x....x.......x...x.
                org $4320 : dg ..x..xx...x......xx..x..
                org $4420 : dg ..x..x.x...xx...x.x..x..
                org $4520 : dg ..x..x..xx....xx..x..x..
                org $4620 : dg ...x..x...xxxx...x..x...
                org $4720 : dg ....x..xx......xx..x....
                org $4040 : dg .....x...xxxxxx...x.....
                org $4140 : dg ......x..........x......
                org $4240 : dg .......xxxxxxxxxx.......

                org $5800
                loop $300
                        db %00000111
                lend

                org $8000

Start           ld d, 200
                ld e, 0
                call Fill
                ret

                org $9000

StackBotSentinel equ $ffff

; Scan-line fill algorithm.
;
; de = xy.
Fill            ld hl, StackBotSentinel
                push hl         ; Push sentinel to mark stack bottom.
                push de         ; Push the first stretch to start filling.

FillLp          pop de
                inc de          ; Check for sentinel.
                ld a, d
                or e
                dec de
                ret z           ; We've hit the stack bottom sentinel.

                call Peek
                jr nz, FillLp   ; This is already filled in.

                ld c, a         ; Zero c, used to track above/below pixels.

ScanL           dec d
                ld a, d
                inc a
                jr z, ScanLDone ; Hit LHS.

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

PeekUD          ld a, e
                cp 192
                jr nc, PeekUDFilled
                call Peek
                jr nz, PeekUDFilled

PeekUDBlank     bit 1, c
                set 1, c
                ret nz          ; We've already pushed a location on this stretch.

                pop hl          ; This is a new stretch above/below.  Push the location.
                push de
                jp (hl)

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

