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

Start           ei
                ld de, GhostBitmap
                ld hl, GhostFrames
                call Unpack16x16
                ld ix, GhostFrames
                call Preshift16x16
                call Demo

                ld de, $547c
                ld hl, GhostFrames
                ld c, 1 * 64 + 6 * 8
                call ResetBorder
                call FastDraw16x16
                call CycleBorder
                call FastDrawCells
                call CycleBorder
                call BlankPrevCells
                halt

Demo            call ResetBorder
                ld b, NDemoObjs
                ld c, 8
                ld ix, DemoObjs
DO_X            ld a, (ix + 0)  ; x
                add a, (ix + 2) ; dx
                cp 256 - 16
                jr nc, DO_BounceX
                ld (ix + 0), a
DO_Y            ld e, a
                ld a, (ix + 1)  ; y
                add a, (ix + 3) ; dy
                cp 192 - 16
                jr nc, DO_BounceY
                ld (ix + 1), a
DO_Colour       ld d, a
                dec c
                jr nz, DO_Draw
                ld c, 7
DO_Draw         ld hl, GhostFrames
                push bc
                call FastDraw16x16
                pop bc
                inc ix
                inc ix
                inc ix
                inc ix
                djnz DO_X
                nop
                call CycleBorder
                call FastDrawCells
                call CycleBorder
                call BlankPrevCells
                jp Demo

DO_BounceX      ld a, (ix + 2)
                neg
                ld (ix + 2), a
                ld a, (ix + 0)
                jp DO_Y

DO_BounceY      ld a, (ix + 3)
                neg
                ld (ix + 3), a
                ld a, (ix + 1)
                jp DO_Colour

NDemoObjs       equ 8
DemoObjs        db 120, 88, 4, 2
                db 120, 88, 2, 4
                db 120, 88, -2, 4
                db 120, 88, -4, 2
                db 120, 88, -4, -2
                db 120, 88, -2, -4
                db 120, 88, 2, -4
                db 120, 88, 4, -2

DO_N            db 8

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
FastDrawCells   ld a, (FS_N)
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

                ; See if this is a new cell or overlaps a used cell.

                ld hl, FS_UsedCellMap - $5800
                add hl, de
                ld a, (hl)
                and a
                jp nz, FDA_Overlapping

                ; This is a new cell.
                ; See if we've reached our limit.
                ; Update FS_UsedCellMap.

                ld a, (FS_N)
                cp FS_MaxN
                jp nc, FDA_Full
                inc a
                ld (FS_N), a
                ld (hl), a

                ; Record the new draw cell address in FS_UsedList.

                push de
                ex de, hl
                ld hl, (FS_UsedCellNext)
                ld (hl), e
                inc hl
                ld (hl), d
                inc hl
                ld (FS_UsedCellNext), hl
                pop de

                ; Fill in the new FS_DrawList entry.

FDA_New         ld hl, (FS_DrawListNext)
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
                ld (FS_DrawListNext), de
                ret

FDA_Overlapping ld h, 0
                ld l, a
                add hl, hl
                add hl, hl
                ld d, h
                ld e, l
                add hl, hl
                add hl, de
                ld de, FS_DrawList - FS_DrawListCellSz + 4
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

BlankPrevCells  ld a, (FS_PrevN)
                and a
                jr z, BK_Reset

                ld b, a
                ld (FS_SP), sp
                ld sp, FS_PrevCellList
                ld de, $5800 - FS_UsedCellMap
                xor a

BK_BlankLp      pop hl
                cp (hl)
                jr nz, BK_BlankNext
                add hl, de
                ld (hl), $ff      ; SMC!
FastDrawBlankAttr equ $ - 1
BK_BlankNext    djnz BK_BlankLp
                ld sp, (FS_SP)

BK_Reset        ld a, (FS_N)
                ld (FS_PrevN), a
                and a
                ret z
                ld b, a
                ld (FS_SP), sp
                ld sp, FS_UsedCellList
                ld hl, FS_PrevCellList
                xor a
                ld (FS_N), a

BK_ResetLp      pop de
                ld (de), a
                ld (hl), e
                inc hl
                ld (hl), d
                inc hl
                djnz BK_ResetLp

                ld sp, (FS_SP)
                ld hl, FS_UsedCellList
                ld (FS_UsedCellNext), hl
                ld hl, FS_DrawList
                ld (FS_DrawListNext), hl
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
FastDraw16x16   push bc

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

ResetBorder     ld a, 7
                ld (FS_BorderColour), a
CycleBorder     ld a, (FS_BorderColour)
                inc a
                and $07
                ld (FS_BorderColour), a
                jr z, CycleBorder
                out (254), a
                ret

FS_N            db 0
FS_PrevN        db 0
FS_MaxN         equ 100
FS_SP           dw 0
                org $b000 - 2
FS_DrawListNext dw FS_DrawList
FS_DrawListCellSz equ 12
FS_DrawList     ds FS_MaxN * FS_DrawListCellSz
                org $c000
FS_UsedCellMap  ds 32 * 24
                org $d000 - 2
FS_UsedCellNext dw FS_UsedCellList
FS_UsedCellList ds FS_MaxN * 2
                org $e000
FS_PrevCellList ds FS_MaxN * 2
FS_BorderColour db 0

