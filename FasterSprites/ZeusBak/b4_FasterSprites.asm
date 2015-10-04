                emulate_spectrum "48k"
                output_szx "FasterSprites.szx", 0, Start
                org $8000

; TODO
; - DONE Fast drawing from draw list.
; - DONE Add new cell to draw list.
; - DONE Handle overlapping cells.
; - DONE Unpack a sprite bitmap.
; - Preshift a sprite bitmap into a full set of frames.
; - Track used cells.
; - Handle blanking based on prev/current used cells.

Start           nop
                ld de, GhostBitmap
                ;ld de, SpriteBitmapC
                ld hl, GhostFrames
                call Unpack16x16
                ld ix, GhostFrames
                call Preshift16x16
                ld hl, GhostFrames + 0 + 4 * 72 + 4
                ld de, $5800
                ld c, $47
                call FastDrawAdd
                ld hl, GhostFrames + 8 + 4 * 72 + 4
                ld de, $5820
                ld c, $47
                call FastDrawAdd
                ld hl, GhostFrames + 24 + 4 * 72 + 4
                ld de, $5801
                ld c, $47
                call FastDrawAdd
                ld hl, GhostFrames + 32 + 4 * 72 + 4
                ld de, $5821
                ld c, $47
                call FastDrawAdd
                ld hl, SpriteBitmapB
                ld de, $5801
                ld c, $43
                ; call FastDrawAdd
                call FastDraw
                halt

SpriteBitmapA   dw $4488, $1122, $4488, $1122
SpriteBitmapB   dw $2211, $8844, $2211, $8844
SpriteBitmapC   db $10, $20, $11, $21, $12, $22, $13, $23, $14, $24, $15, $15, $16, $26, $17, $27
                db $18, $28, $19, $29, $1a, $2a, $1b, $2b, $1c, $2c, $1d, $2d, $1e, $2e, $1f, $2f

GhostBitmap     dg ................
                dg ......xxxx......
                dg ....xxxxxxxx....
                dg ...xxxxxxxxxx...
                dg ..x..xxxx..xxx..
                dg ......xx....xx..
                dg ..xx..xxxx..xx..
                dg .xxx..xxxx..xxx.
                dg .xx..xxxx..xxxx.
                dg .xxxxxxxxxxxxxx.
                dg .xxxxxxxxxxxxxx.
                dg .xxxxxxxxxxxxxx.
                dg .xxxxxxxxxxxxxx.
                dg .xx.xxx..xxx.xx.
                dg .x...xx..xx...x.
                dg ................

                org $9000
GhostFrames     ds 8 + 8 * 64

                org $a000
; Draw all cells in the FD_DrawList.
; Trashes abdehl.
FastDraw        ld a, (FD_N)
                and a
                ret z
                ld b, a
                ld (FD_SP), sp
                ld sp, FD_DrawList

FD_Loop         pop hl
                pop de
                ld (hl), e
                ld h, d
                loop 3
                        pop de
                        ld (hl), e
                        inc h
                        ld (hl), d
                        inc h
                lend
                pop de
                ld (hl), e
                inc h
                ld (hl), d
                djnz FD_Loop

FD_End          ld sp, (FD_SP)
                ret

; Add a cell to the FD_DrawList.
; In: hl = bitmap ptr, de = attr ptr, c = attr.
; Out: hl = bitmap ptr + 8.
; Trashes abcde.
FastDrawAdd     push hl
                ld hl, FD_UsedCells - $5800
                add hl, de
                ld a, (hl)
                and a
                jp nz, FDA_Overlapping

                ld a, (FD_N)
                cp FD_MaxN
                jp nc, FDA_Full
                inc a
                ld (FD_N), a
                ld (hl), a

FDA_New         ld hl, (FD_NextFree)
                ld (hl), e
                inc hl
                ld (hl), d
                inc hl
                ld (hl), c
                inc hl
                ld a, d         ; a = %010110tt
                rlca
                rlca
                rlca            ; a = %110tt010
                xor %10000010   ; a = %010tt000
                ld (hl), a
                inc hl
                ex de, hl
                pop hl
                loop 8
                        ldi
                lend
                ld (FD_NextFree), de
                ret

FDA_Overlapping ld h, 0
                ld l, a
                add hl, hl
                add hl, hl
                ld d, h
                ld e, l
                add hl, hl
                add hl, de
                ld de, FD_DrawList - FD_DrawDataSz + 4
                add hl, de
                ex de, hl
                pop hl
                loop 8
                        ld a, (de)
                        or (hl)
                        ld (de), a
                        inc de
                        inc hl
                lend
                ret

FDA_Full        pop hl
                loop 8
                        inc hl
                lend
                ret

; Unpack a 16x16 bitmap into a sprite frame.
; In: de = src, hl = tgt.
; Out: hl = src + 16.
; Trashes abcdeix.
Unpack16x16     push de
                push hl
                ld d, h
                ld e, l
                inc de
                ld (hl), 0
                ld bc, 3 * (16 + 8) - 1
                ldir            ; Clear out the target frame buffer.
                pop ix          ; ix = tgt
                pop hl          ; hl = src
                ld b, 16
UP_Lp           ld a, (hl)
                ld (ix + 8), a
                inc hl
                ld a, (hl)
                ld (ix + 32), a
                inc hl
                inc ix
                djnz UP_Lp
                ret

; Pre-shift a sprite frame to make the next seven,
; shifted consecutive pixels to the right.
; In: ix = src.
Preshift16x16   ld de, 3 * 24 - 16
                ld c, 7
PS_Lp1          ld b, 16
                xor a
PS_Lp2          ld a, (ix + 8 + 0 * 24)
                rra
                ld (ix + 8 + 3 * 24), a
                ld a, (ix + 8 + 1 * 24)
                rr a
                ld (ix + 8 + 4 * 24), a
                ld a, (ix + 8 + 2 * 24)
                rra
                inc ix
                ld (ix + 8 + 5 * 24 - 1), a ; Max offset is 127!
                djnz PS_Lp2
                add ix, de
                dec c
                jr nz PS_Lp1
                ret

FD_N            db 0
FD_MaxN         equ 100
FD_SP           dw 0
FD_NextFree     dw FD_DrawList
FD_DrawDataSz   equ 12
FD_DrawList     ds FD_MaxN * FD_DrawDataSz
FD_UsedCells    ds 32 * 24

