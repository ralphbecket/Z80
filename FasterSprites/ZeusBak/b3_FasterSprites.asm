                emulate_spectrum "48k"
                output_szx "FasterSprites.szx", 0, Start
                org $8000

; TODO
; - DONE Fast drawing from draw list.
; - DONE Add new cell to draw list.
; - DONE Handle overlapping cells.
; - DONE Unpack a sprite bitmap.
; - DONE Preshift a sprite bitmap into a full set of frames.
; - Add draw cells for a 16x16 sprite at (x,y) pixels (no clipping).
; - Track used cells.
; - Handle blanking based on prev/current used cells.

Start           nop
                ld de, GhostBitmap
                ;ld de, SpriteBitmapC
                ld hl, GhostFrames
                call Unpack16x16
                ld ix, GhostFrames
                call Preshift16x16
XShift equ 6
                ld de, $7c7c
                ld hl, GhostFrames
                ld c, 1 * 64 + 6 * 8
                call Draw16x16

                ;ld hl, GhostFrames + 0 + XShift * 72 + 4
                ;ld de, $5800
                ;ld c, $47
                ;call FastDrawAddCell
                ;ld hl, GhostFrames + 8 + XShift * 72 + 4
                ;ld de, $5820
                ;ld c, $47
                ;call FastDrawAddCell
                ;ld hl, GhostFrames + 24 + XShift * 72 + 4
                ;ld de, $5801
                ;ld c, $47
                ;call FastDrawAddCell
                ;ld hl, GhostFrames + 32 + XShift * 72 + 4
                ;ld de, $5821
                ;ld c, $47
                ;call FastDrawAddCell
                ;ld hl, SpriteBitmapB
                ;ld de, $5801
                ;ld c, $43
                ; call FastDrawAddCell

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
; Draw all cells in the FS_DrawList.
; Trashes abdehl.
FastDraw        ld a, (FS_N)
                and a
                ret z
                ld b, a
                ld (FS_SP), sp
                ld sp, FS_DrawList

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

FD_End          ld sp, (FS_SP)
                ret

; Add a cell to the FD_DrawList.
; In: hl = bitmap ptr, de = attr ptr, c = attr.
; Out: hl = bitmap ptr + 8.
; Trashes abcde.
FastDrawAddCell push hl
                ld hl, FS_UsedCells - $5800
                add hl, de
                ld a, (hl)
                and a
                jp nz, FDA_Overlapping

                ld a, (FS_N)
                cp FS_MaxN
                jp nc, FDA_Full
                inc a
                ld (FS_N), a
                ld (hl), a

FDA_New         ld hl, (FS_NextFree)
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
                ld (FS_NextFree), de
                ret

FDA_Overlapping ld h, 0
                ld l, a
                add hl, hl
                add hl, hl
                ld d, h
                ld e, l
                add hl, hl
                add hl, de
                ld de, FS_DrawList - FS_CellDataSz + 4
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
; Out: ix = frame top.
; Trashes: abcde.
Preshift16x16   ld de, 8
                add ix, de
                ld de, 3 * 24 - 16
                ld c, 7
PS_Lp1          ld b, 16
                xor a
PS_Lp2          ld a, (ix + 0 * 24)
                rra
                ld (ix + 3 * 24), a
                ld a, (ix + 1 * 24)
                rr a
                ld (ix + 4 * 24), a
                ld a, (ix + 2 * 24)
                rra
                ld (ix + 5 * 24), a ; Max offset is 127!
                inc ix
                djnz PS_Lp2
                add ix, de
                dec c
                jr nz PS_Lp1
                ret

; Draw an unpacked, pre-shifted sprite at the given (x, y) pixel
; coordinates.  Note: this does not perform clipping; drawing off
; the edges of the display will result in undefined behaviour.
; In: d = y, e = x, hl = frames ptr, c = attr.
Draw16x16       push bc

                ld a, d
                cpl
                and 7
                ld c, a
                ld a, e
                and 7
                rla
                rla
                rla
                or c
                ld c, a
                and $f8
                rla
                rla
                ld b, 0
                rla
                rl b
                or c
                ld c, a
                inc bc
                add hl, bc      ; hl = frame ptr.

                ld a, d
                rra
                rra
                rra
                rra
                rr e
                rra
                rr e
                rra
                rr e
                and $03
                or $58
                ld d, a         ; de = attr ptr.

                loop 3
                        loop 3
                                pop bc
                                push bc
                                push de
                                call FastDrawAddCell
                                pop de
                                ex de, hl
                                ld bc, 32
                                add hl, bc
                                ex de, hl
                        lend
                        ex de, hl
                        ld bc, 1 - 3 * 32
                        add hl, bc
                        ex de, hl
                lend
                pop bc
                ret

FS_N            db 0
FS_PrevN        db 0
FS_MaxN         equ 100
FS_SP           dw 0
FS_NextFree     dw FS_DrawList
FS_CellDataSz   equ 12
FS_DrawList     ds FS_MaxN * FS_CellDataSz
FS_UsedCells    ds 32 * 24
FS_PrevCells    ds FS_MaxN * 2

