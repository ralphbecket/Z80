; Maze.asm

; The maze is represented by a table of pointers to drawing routines.
; Each consecutive row of pointers starts on the next $100 page boundary.
; This makes it very easy to turn a coordinate into the corresponding
; maze map entry address.  (I could reuse the wasted space or just
; store the rows consecutively, but for this demo I really don't care.)
;
; This scheme allows for very fast full-screen drawing.  Each drawing
; routine in-lines writing either a fixed solid colour attribute or an
; attribute and a dixed cell bitmap.  Provided no more than 33% of cells
; have bitmaps, we can redraw the entire display before the CRT beam
; catches us.
;
; Drawing works by pointing SP to the maze address for the upper left
; corner of the window to display and simply executing 'ret'.
; Before doing so, however, we need to ensure that the 33rd entry in
; each row in the "window" is updated to point to the appropriate
; "start the next row" routine, which is responsible for fixing up the
; attribute and display file addresses.  After drawing, the maze must
; be repaired by replacing these "fix up" entries with their original
; contents.

; The DrawAttr and DrawBitmap macros encode a single attribute cell
; write or an attribute and bitmap cell write.  It assumes that HL will
; point to the attribute cell, DE to the bitmap cell, that
; BC = 1 - $700, SP points to the next maze address, and IX points to
; the first maze address (i.e., for the top left corner cell being
; displayed).

; Note: there are nine special points in the map used to indicate
; junction points in the maze.  All drawing routines except for
; these must start on a low-byte address 16 or greater.  This is a
; "clever hack".

DrawAlignHack macro()
        while ($ & $ff) < 16
                nop
        endw
endm

DrawAttr macro(attr)
        ld (HL), attr
        inc L
        inc E
        ret
endm

DrawBitmap macro(attr, x0, x1, x2, x3, x4, x5, x6, x7)
        ld (HL), attr
        inc L
        ex DE, HL
        ld (HL), x0
        inc H
        ld (HL), x1
        inc H
        ld (HL), x2
        inc H
        ld (HL), x3
        inc H
        ld (HL), x4
        inc H
        ld (HL), x5
        inc H
        ld (HL), x6
        inc H
        ld (HL), x7
        add HL, BC
        ex DE, HL
        ret
endm



; The various maze drawing routines.

        align $100
; First the junction points, which alias to the "draw a black cell" code.
Ja      nop
Jb      nop
Jc      nop
Jd      nop
Je      nop
Jf      nop
Jg      nop
Jh      nop
Ji      nop
        DrawAlignHack()
; Then the various maze drawing routines.
BB      DrawAttr(SolidBlack)
        DrawAlignHack()
WW      DrawAttr(SolidBlue)
        DrawAlignHack()
TL      DrawBitmap(FgBlue,              $00, $07, $1f, $3f, $3f, $7f, $7f, $7f)
        DrawAlignHack()
BL      DrawBitmap(FgBlue,              $7f, $7f, $7f, $3f, $3f, $1f, $07, $00)
        DrawAlignHack()
TR      DrawBitmap(FgBlue,              $00, $e0, $f8, $fc, $fc, $fe, $fe, $fe)
        DrawAlignHack()
BR      DrawBitmap(FgBlue,              $fe, $fe, $fe, $fc, $fc, $f8, $e0, $00)
        DrawAlignHack()
DD      DrawBitmap(FgYellow,            $00, $00, $18, $3c, $3c, $18, $00, $00)
        DrawAlignHack()
PP      DrawBitmap(FgYellow + Bright,   $3c, $7e, $ff, $ff, $ff, $ff, $7e, $3c)
        DrawAlignHack()
QM      DrawBitmap(FgYellow + Flash,    $3c, $7e, $66, $0c, $18, $00, $18, $18)
        DrawAlignHack()
; This is handy for debugging :-)
Argh    ret



; We want to draw a screen sized window of the maze.  This means
; we need to fix up SP (the "draw list" pointer) and possibly DE
; (the display bitmap pointer) at the end of each row.

; This is where we fix things up so the end-of-row adjustments
; are made.  Upon reflection, it's probably a little too "clever"
; and could be made much simpler.  But I'm not changing it now.
;
; DE is the addr of the top left maze cell to draw on screen.
;
PrepRedrawMaze proc

        ld (RedrawMazeInitialSP), DE
        ld HL, 2 * DisplayWidth                 ; The number of bytes spanning the display width.
        add HL, DE
        ld (RedrawMazeInitialAdj), HL

        ld DE, RestoreMazeAfterRedraw + 4       ; SMC ...
        ld BC, AdjForNextRow

        for ii = 1 to 24
                ld A, (HL)
                ld (DE), A
                if ii = 8
                        ld (HL), high(AdjForEndRow8)
                        dec L
                elif ii = 16
                        ld (HL), high(AdjForEndRow16)
                        dec L
                elif ii = 24
                        ld (HL), high(AdjForEndRow24)
                        dec L
                elif ii & 1
                        ld (HL), C
                        inc L
                else
                        ld (HL), B
                        dec L
                endif
                inc DE
                inc DE
                inc DE
                ld A, (HL)
                ld (DE), A
                if ii = 8
                        ld (HL), low(AdjForEndRow8)
                elif ii = 16
                        ld (HL), low(AdjForEndRow16)
                elif ii = 24
                        ld (HL), low(AdjForEndRow24)
                elif ii & 1
                        ld (HL), B
                else
                        ld (HL), C
                endif
                inc H
                inc DE
                inc DE
                inc DE
        next
        ret
endp

RestoreMazeAfterRedraw proc
        ld HL, (RedrawMazeInitialAdj)
        loop DisplayHeight / 2
                ld (HL), 00     ; SMC ...
                inc L
                ld (HL), 00
                inc H
                ld (HL), 00
                dec L
                ld (HL), 00
                inc H
        endl
        ret
endp

RedrawMaze proc
        ld (RedrawMazeStoredSP), SP
        ld IX, (RedrawMazeInitialSP)
        ld SP, IX
        ld DE, $4000
        ld HL, $5800
        ld BC, 1 - $700
        ret
endp

AdjForNextRow proc
        inc IXH
        ld SP, IX
        ret
endp

AdjForEndRow8 proc
        inc IXH         ; AdjForEndRow8
        ld SP, IX
        ld DE, $4800
        ld HL, $5900
        ret
endp

AdjForEndRow16 proc
        inc IXH         ; AdjForEndRow16
        ld SP, IX
        ld DE, $5000
        ld HL, $5a00
        ret
endp

AdjForEndRow24 proc
        ld SP, (RedrawMazeStoredSP) ; AdjForEndRow24
        ret
endp

        align $100

RedrawMazeStoredSP      dw 0
RedrawMazeInitialSP     dw 0
RedrawMazeInitialAdj    dw 0

; Some maze debugging checks.

CalcMazeChecksum proc
        ld HL, Maze
        xor A
        ld C, MazeHeight
_1      ld B, MazeWidth
_2      add A, (HL)
        inc L
        djnz _2
        inc H
        ld L, 0
        dec C
        jr nz, _1
        ret
endp

; Generating the maze representation.
; Each maze cell is represented by the address of the corresponding drawing routine.
; Rows are aligned on consecutive $100 byte address boundaries.

MazeCell macro(x)
        dw      ( x = " " ? BB
                : x = "#" ? WW
                : x = "1" ? TL
                : x = "2" ? TR
                : x = "3" ? BL
                : x = "4" ? BR
                : x = "." ? DD
                : x = "O" ? PP
                : x = "a" ? Ja
                : x = "b" ? Jb
                : x = "c" ? Jc
                : x = "d" ? Jd
                : x = "e" ? Je
                : x = "f" ? Jf
                : x = "g" ? Jg
                : x = "h" ? Jh
                : x = "i" ? Ji
                : QM
                )
endm

MazeRow macro(x)
        align $100
        for ii = 1 to length(x)
                MazeCell(x[ii])
        next
        while ($ & $ff) < 200
                dw Argh ; Just in case we need to debug this thing...
        endw
endm

; Legend:
;
; 1, 2, 3, 4 denote top left/right and bottom left/right wall corners;
;
; # denotes a wall;
;
; . and O denote dots and power pills;
;
; a-b-c
; | | |
; d-e-f denote the navigation markers at intersections;
; | | |
; g-h-i
;
; L and R denote the left and right tunnel mouths.

MazeWidth       equ 55
MazeHeight      equ 57
        org $9000
Maze
        MazeRow("1#########################2 1#########################2")
        MazeRow("#a         b           c  # #a           b         c  #")
        MazeRow("# . . . . . . . . . . . . # # . . . . . . . . . . . . #")
        MazeRow("#                         # #                         #")
        MazeRow("# . 1#####2 . 1#######2 . # # . 1#######2 . 1#####2 . #")
        MazeRow("#   #     #   #       #   # #   #       #   #     #   #")
        MazeRow("# O #     # . #       # . # # . #       # . #     # O #")
        MazeRow("#   #     #   #       #   # #   #       #   #     #   #")
        MazeRow("# . 3#####4 . 3#######4 . 3#4 . 3#######4 . 3#####4 . #")
        MazeRow("#d         e     b     h     h     b     e         f  #")
        MazeRow("# . . . . . . . . . . . . . . . . . . . . . . . . . . #")
        MazeRow("#                                                     #")
        MazeRow("# . 1#####2 . 1#2 . 1#############2 . 1#2 . 1#####2 . #")
        MazeRow("#   #     #   # #   #             #   # #   #     #   #")
        MazeRow("# . 3#####4 . # # . 3###### ######4 . # # . 3#####4 . #")
        MazeRow("#g         f  # #g     c  # #a     i  # #d         i  #")
        MazeRow("# . . . . . . # # . . . . # # . . . . # # . . . . . . #")
        MazeRow("#             # #         # #         # #             #")
        MazeRow("3#########2 . # 3#####2   # #   1#####4 # . 1#########4")
        MazeRow("          #   #       #   # #   #       #   #          ")
        MazeRow("          # . # 1#####4   3#4   3#####2 # . #          ")
        MazeRow("          #   # #a     h     h     c  # #   #          ")
        MazeRow("          # . # #                     # # . #          ")
        MazeRow("          #   # #                     # #   #          ")
        MazeRow("##########4 . 3#4   1#####   #####2   3#4 . 3##########")
        MazeRow("L          d     f  #             #d     f          R  ") ; XXX These are wrong for now.
        MazeRow("                    #             #                    ")
        MazeRow("                    #             #                    ")
        MazeRow("##########2 . 1#2   3#############4   1#2 . 1##########")
        MazeRow("          #   # #d                 f  # #   #          ")
        MazeRow("          # . # #                     # # . #          ")
        MazeRow("          #   # #                     # #   #          ")
        MazeRow("          # . # #   1#############2   # # . #          ")
        MazeRow("          #   # #   #             #   # #   #          ")
        MazeRow("1#########4 . 3#4   3#####2 1#####4   3#4 . 3#########2")
        MazeRow("#a         e     h     c  # #a     h     e         c  #")
        MazeRow("# . . . . . . . . . . . . # # . . . . . . . . . . . . #")
        MazeRow("#                         # #                         #")
        MazeRow("# . 1#####2 . 1#######2 . # # . 1#######2 . 1#####2 . #")
        MazeRow("#   #     #   #       #   # #   #       #   #     #   #")
        MazeRow("# . 3###2 # . 3#######4 . 3#4 . 3#######4 . # 1###4 . #")
        MazeRow("#g   c  # #d     b     h     h     b     f  # #a   i  #")
        MazeRow("# O . . # # . . . . . . .     . . . . . . . # # . . O #")
        MazeRow("#       # #                                 # #       #")
        MazeRow("####2 . # # . 1#2 . 1#############2 . 1#2 . # # . 1####")
        MazeRow("#   #   # #   # #   #             #   # #   # #   #   #")
        MazeRow("####4 . 3#4 . # # . 3###### ######4 . # # . 3#4 . 3####")
        MazeRow("#a   h     i  # #g     c  # #a     i  # #g     h   c  #")
        MazeRow("# . . . . . . # # . . . . # # . . . . # # . . . . . . #")
        MazeRow("#             # #         # #         # #             #")
        MazeRow("# . 1#########4 3#####2 . # # . 1#####4 3#########2 . #")
        MazeRow("#   #                 #   # #   #                 #   #")
        MazeRow("# . 3#################4 . 3#4 . 3#################4 . #")
        MazeRow("#g                     h     h                     i  #")
        MazeRow("# . . . . . . . . . . . . . . . . . . . . . . . . . . #")
        MazeRow("#                                                     #")
        MazeRow("3#####################################################4")


; Maze junction exits.  Directions 0123 correspond to ESWN.
; The nine possible junction kinds are assigned labels 0..8.
; This table shows, for each junction kind, the possible
; non-reversing exit directions.
; Each byte contains four exit directions in bit pairs.
; The number of exits have been duplicated up to ensure there
; are four listed for each junction.
; This means that one can make a random choice of four exits
; at each junction without having to perform any complicated
; logic.
;
; Yes, this was generated with a little script.  Not by hand.
        align $100
JunctionExitsTable
JaExits db $00, $00, $55, $00
JbExits db $44, $00, $99, $88
JcExits db $55, $00, $00, $aa
JdExits db $00, $44, $dd, $cc
JeExits db $f4, $24, $79, $f8
JfExits db $dd, $99, $00, $ee
JgExits db $00, $00, $ff, $00
JhExits db $cc, $88, $ee, $00
JiExits db $ff, $aa, $00, $00



