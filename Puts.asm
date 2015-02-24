; PutC(a = char)
;
                if usePropChars
                include "PutPropCh.asm"
PutCh           equ PutPropCh
                else
PutCh           proc

                cp 13
                jr z, PutNL

                sub 32
                jr nc, charOK
                ld a, '?' - 32
charOK          push af                 ; Save the char.

                call MaybeScroll

                ld hl, (PutAttrPtr)     ; Write the attr.
                ld a, (PutAttr)
                ld (hl), a

                inc hl
                ld (PutAttrPtr), hl
                dec hl

                ld a, h                 ; Convert to disp ptr.
                and %00001111
                add a, a
                add a, a
                add a, a
                ld h, a
                ex de, hl               ; de = disp ptr.

                pop af                  ; Retrieve the char.
                ld h, 0
                ld l, a
                add hl, hl
                add hl, hl
                add hl, hl              ; hl = char bitmap ptr.
                ld bc, (CharSet)
                add hl, bc

                loop 8                  ; Draw the char bitmap.
                ld a, (hl)
                if usePropChars
                and %11111000          ; Hack when using PropChars.
                endif
                ld (de), a
                inc hl
                inc d
                lend

                ret

                endp
                endif

PutSpc          ld a, ' '
                jp PutCh

PutNL           proc

                if usePropChars
                xor a
                ld (PutPropX), a
                endif

                ld hl, (PutAttrPtr)
                ld de, $20
                add hl, de
                ld a, l
                and %11100000
                ld l, a
                ld (PutAttrPtr), hl
                ret

                endp

; PutStr (hl = null terminated string ptr; hl = addr of terminating null).
;
PutStr          proc

                ld a, (hl)
                and a
                ret z
                push hl
                call PutCh
                pop hl
                inc hl
                jr PutStr

                endp

; Puts (hl = null terminated string ptr).
;
PutStrNL        call PutStr
                jp PutNL

; PutStrN (hl = string ptr, de = max chars to print)
;
PutStrN         ld a, d
                or e
                ret z
                ld a, (hl)
                or a
                ret z
                inc hl
                dec de
                push hl
                push de
                call PutCh
                pop de
                pop hl
                jp PutStrN

; PutInt(hl = int)
;
PutInt          bit 7, h
                jr z, PutUInt
                push hl                 ; Print a '-' and negate.
                ld a, '-'
                call PutCh
                pop hl
                and a
                ld de, 0
                ex de, hl
                sbc hl, de

; PutUInt(hl = int).
;
PutUInt         proc

                ld a, h
                or l
                jr nz, notZero
                ld a, '0'               ; Handle zero as a special case.
                jp PutCh

notZero         ld b, 0                 ; Note if we've output anything.

                xor a
                ld de, 10000
                call putColumn
                ld de, 1000
                call putColumn
                ld de, 100
                call putColumn
                ld de, 10
                call putColumn
                ld de, 1
                call putColumn

                ret

putColumn       inc a
                sbc hl, de
                jr nc, putColumn
                add hl, de
                dec a

putDigit        add a, b
                ret z                   ; Don't print leading zeroes.
                sub b
                ld b, 1
                push hl
                push bc
                add a, '0'
                call PutCh
                pop bc
                pop hl
                xor a
                ret

                endp

PutHexDigit     proc
                and $0f
                add a, '0'
                cp '0' + 10
                jr c, putX
                add a, 'a' - '0' - 10
putX            jp PutCh
                endp

PutHexByte      push af
                rrca
                rrca
                rrca
                rrca
                call PutHexDigit
                pop af
                jp PutHexDigit

PutHexWord      push hl
                ld a, h
                call PutHexByte
                pop hl
                ld a, l
                jp PutHexByte

MaybeScroll     proc

                ld hl, (PutAttrPtr)
                ld a, h
                cp $5b
                ret c
                call Scroll
                ld hl, AttrFile + $300 - $20
                ld (PutAttrPtr), hl
                ret

                endp

Scroll          proc

                ld hl, AttrFile
                ld (toAttrPtr), hl
                ld hl, AttrFile + $20
                ld (fromAttrPtr), hl
                ld hl, DispFile
                ld (toDispPtr), hl
                ld a, 23
                ld (lineCount), a

l1              ld de, (toAttrPtr)      ; Copy a line of attrs.
                ld hl, (fromAttrPtr)
                ld bc, $20
                ldir
                ld (fromAttrPtr), hl
                ld (toAttrPtr), de

                ex de, hl               ; Get the to/from disp ptrs.
                ld de, (toDispPtr)
                ld a, h
                and %00001111
                add a, a
                add a, a
                add a, a
                ld h, a
                ld (toDispPtr), hl

                ld b, 8                 ; Copy the row bitmaps.
l2              push bc
                push hl
                push de
                ld bc, $20
                ldir
                pop de
                pop hl
                inc h
                inc d
                pop bc
                djnz l2

                ld hl, lineCount        ; Repeat until done.
                dec (hl)
                jr nz, l1

                call GetBlankPAttr      ; Clear the last line.
                ld hl, (toAttrPtr)
                ld (hl), a
                ld d, h
                ld e, l
                inc de
                ld bc, $20 - 1
                ldir

                ret

toAttrPtr       dw 0
fromAttrPtr     dw 0
toDispPtr       dw 0
lineCount       db 0

                endp

Cls             if usePropChars
                xor a
                ld (PutPropX), a
                endif

                call GetBlankPAttr
                ld hl, AttrFile
                ld (PutAttrPtr), hl
                ld de, AttrFile + 1
                ld bc, $20 * 24 - 1
                ld (hl), a
                ldir
                ret

GetBlankPAttr   proc

                ld a, (PutAttr)

                ld c, a

                and %00111000
                ld b, a
                rrca
                rrca
                rrca
                add a, b

                bit 6, c
                ret z
                set 6, a
                ret

                endp


