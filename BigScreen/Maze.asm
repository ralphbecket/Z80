; This is taken from the classic PacMan maze.

MoveMazeViewLeft        ld a, (MazeViewCol)
                        and a
                        ret z
                        dec a
                        ld (MazeViewCol), a
                        ret

MoveMazeViewRight       ld a, (MazeViewCol)
                        inc a
                        cp MazeViewColTop
                        ret nc
                        ld (MazeViewCol), a
                        ret

MoveMazeViewUp          ld a, (MazeViewRow)
                        and a
                        ret z
                        dec a
                        ld (MazeViewRow), a
                        ret

MoveMazeViewDown        ld a, (MazeViewRow)
                        inc a
                        cp MazeViewRowTop
                        ret nc
                        ld (MazeViewRow), a
                        ret

PlotMaze                ld a, (MazeViewRow)     ; Each maze row is 64 bytes.
                        rrca
                        rrca
                        ld b, a
                        and %11111100
                        ld c, a
                        ld a, b
                        and %00000011
                        ld b, a
                        ld a, (MazeViewCol)
                        add a, c
                        ld c, a
                        adc a, b
                        sub a, c
                        ld b, a
                        ld hl, Maze
                        add hl, bc              ; HL is addr of view offset into maze.

                        ld de, ShadowAttrMap
                        ld ixh, 24              ; Row counter.
                        ld ixl, 32              ; Col counter.

pmLoop                  ld a, (hl)              ; Obviously, this could be faster!
                        cp ' '
                        jr z, pmSpace
                        cp '#'
                        jr z, pmWall
                        cp '.'
                        jr z, pmDot
                        cp 'O'
                        jr z, pmPill
                        cp '1'
                        jr z, pmSE
                        cp '2'
                        jr z, pmSW
                        cp '3'
                        jr z, pmNW
                        cp '4'
                        jr z, pmNE
                        cp '/'
                        jr z, pmCageWall
                        cp 'a'
                        jr z, pmCageSE
                        cp 'b'
                        jr z, pmCageSW
                        cp 'c'
                        jr z, pmCageNW
                        cp 'd'
                        jr z, pmCageNE

pmSpace                 ld a, BlackInk + BlackPaper + Flash
                        ld (de), a
                        jr pmNextCol

pmWall                  ld a, BlueInk + BluePaper + Flash
                        ld (de), a
                        jr pmNextCol

pmDot                   ld a, YellowInk
                        ld bc, DotBitmap
                        jr pmPlotCell

pmPill                  ld a, YellowInk
                        ld bc, PillBitmap
                        jr pmPlotCell

pmSE                    ld a, BlueInk
                        ld bc, SEBitmap
                        jr pmPlotCell

pmSW                    ld a, BlueInk
                        ld bc, SWBitmap
                        jr pmPlotCell

pmNE                    ld a, BlueInk
                        ld bc, NEBitmap
                        jr pmPlotCell

pmNW                    ld a, BlueInk
                        ld bc, NWBitmap
                        jr pmPlotCell

pmCageWall              ld a, MagentaInk + MagentaPaper + Flash
                        ld (de), a
                        jr pmNextCol

pmCageSE                ld a, MagentaInk
                        ld bc, SEBitmap
                        jr pmPlotCell

pmCageSW                ld a, MagentaInk
                        ld bc, SWBitmap
                        jr pmPlotCell

pmCageNE                ld a, MagentaInk
                        ld bc, NEBitmap
                        jr pmPlotCell

pmCageNW                ld a, MagentaInk
                        ld bc, NWBitmap
                        jr pmPlotCell

pmPlotCell              ld (de), a
                        push de
                        inc d
                        inc d
                        inc d
                        ld a, c
                        ld (de), a
                        inc d
                        inc d
                        inc d
                        ld a, b
                        ld (de), a
                        pop de

pmNextCol               inc de
                        inc hl
                        dec ixl
                        jp nz, pmLoop
                        ld ixl, 32

pmNextRow               ld bc, 64 - 32
                        add hl, bc
                        ;ex de, hl
                        ;ld bc, 32 - 24
                        ;add hl, bc
                        ;ex de, hl
                        dec ixh
                        jp nz, pmLoop

                        ret

MazeWidth               equ 64
MazeHeight              equ 57
MazeViewRow             db 0
MazeViewCol             db 0
MazeViewRowTop          equ MazeHeight - 23
MazeViewColTop          equ MazeWidth - 23 - 9
Maze                    equ *
    db "1#########################2 1#########################2         "
    db "#                         # #                         #         "
    db "# . . . . . . . . . . . . # # . . . . . . . . . . . . #         "
    db "#                         # #                         #         "
    db "# . 1#####2 . 1#######2 . # # . 1#######2 . 1#####2 . #         "
    db "#   #     #   #       #   # #   #       #   #     #   #         "
    db "# O #     # . #       # . # # . #       # . #     # O #         "
    db "#   #     #   #       #   # #   #       #   #     #   #         "
    db "# . 3#####4 . 3#######4 . 3#4 . 3#######4 . 3#####4 . #         "
    db "#                                                     #         "
    db "# . . . . . . . . . . . . . . . . . . . . . . . . . . #         "
    db "#                                                     #         "
    db "# . 1#####2 . 1#2 . 1#############2 . 1#2 . 1#####2 . #         "
    db "#   #     #   # #   #             #   # #   #     #   #         "
    db "# . 3#####4 . # # . 3###### ######4 . # # . 3#####4 . #         "
    db "#             # #         # #         # #             #         "
    db "# . . . . . . # # . . . . # # . . . . # # . . . . . . #         "
    db "#             # #         # #         # #             #         "
    db "3#########2 . # 3#####2   # #   1#####4 # . 1#########4         "
    db "          #   #       #   # #   #       #   #                   "
    db "          # . # 1#####4   3#4   3#####2 # . #                   "
    db "          #   # #                     # #   #                   "
    db "          # . # #                     # # . #                   "
    db "          #   # #                     # #   #                   "
    db "##########4 . 3#4   a/////~~~/////b   3#4 . 3##########         "
    db "                    /             /                             "
    db "            .       /             /       .                     "
    db "                    /             /                             "
    db "##########2 . 1#2   c/////////////d   1#2 . 1##########         "
    db "          #   # #                     # #   #                   "
    db "          # . # #                     # # . #                   "
    db "          #   # #                     # #   #                   "
    db "          # . # #   1#############2   # # . #                   "
    db "          #   # #   #             #   # #   #                   "
    db "1#########4 . 3#4   3#####2 1#####4   3#4 . 3#########2         "
    db "#                         # #                         #         "
    db "# . . . . . . . . . . . . # # . . . . . . . . . . . . #         "
    db "#                         # #                         #         "
    db "# . 1#####2 . 1#######2 . # # . 1#######2 . 1#####2 . #         "
    db "#   #     #   #       #   # #   #       #   #     #   #         "
    db "# . 3###2 # . 3#######4 . 3#4 . 3#######4 . # 1###4 . #         "
    db "#       # #                                 # #       #         "
    db "# O . . # # . . . . . . .     . . . . . . . # # . . O #         "
    db "#       # #                                 # #       #         "
    db "####2 . # # . 1#2 . 1#############2 . 1#2 . # # . 1####         "
    db "#   #   # #   # #   #             #   # #   # #   #   #         "
    db "####4 . 3#4 . # # . 3###### ######4 . # # . 3#4 . 3####         "
    db "#             # #         # #         # #             #         "
    db "# . . . . . . # # . . . . # # . . . . # # . . . . . . #         "
    db "#             # #         # #         # #             #         "
    db "# . 1#########4 3#####2 . # # . 1#####4 3#########2 . #         "
    db "#   #                 #   # #   #                 #   #         "
    db "# . 3#################4 . 3#4 . 3#################4 . #         "
    db "#                                                     #         "
    db "# . . . . . . . . . . . . . . . . . . . . . . . . . . #         "
    db "#                                                     #         "
    db "3#####################################################4         "

