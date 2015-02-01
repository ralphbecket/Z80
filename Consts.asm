ScanCharProps   db retCh                ; 0 = EOF.
                loop 32                 ; $01..$20 are whitespace.
                db skipWS
                endl
                db maybeNE              ; ! or !=
                db retCh                ; "
                db retCh                ; #
                db retCh                ; $
                db retCh                ; %
                db maybeAndAlso         ; & or &&
                db retCh                ; '
                db retCh                ; (
                db retCh                ; )
                db retCh                ; *
                db retCh                ; +
                db retCh                ; ,
                db retCh                ; -
                db retCh                ; .
                db retCh                ; /
                db isDigit              ; 0
                db isDigit              ; 1
                db isDigit              ; 2
                db isDigit              ; 3
                db isDigit              ; 4
                db isDigit              ; 5
                db isDigit              ; 6
                db isDigit              ; 7
                db isDigit              ; 9
                db isDigit              ; 9
                db retCh                ; :
                db retCh                ; ;
                db maybeLE              ; < or <=
                db retCh                ; =
                db maybeGE              ; > or >=
                db retCh                ; ?
                db retCh                ; @
                db isAlpha              ; A
                db isAlpha              ; B
                db isAlpha              ; C
                db isAlpha              ; D
                db isAlpha              ; E
                db isAlpha              ; F
                db isAlpha              ; G
                db isAlpha              ; H
                db isAlpha              ; I
                db isAlpha              ; J
                db isAlpha              ; K
                db isAlpha              ; L
                db isAlpha              ; M
                db isAlpha              ; N
                db isAlpha              ; O
                db isAlpha              ; P
                db isAlpha              ; Q
                db isAlpha              ; R
                db isAlpha              ; S
                db isAlpha              ; T
                db isAlpha              ; U
                db isAlpha              ; V
                db isAlpha              ; W
                db isAlpha              ; X
                db isAlpha              ; Y
                db isAlpha              ; Z
                db retCh                ; [
                db retCh                ; \
                db retCh                ; ]
                db retCh                ; ^
                db isAlpha              ; _
                db retCh                ; `
                db isAlpha              ; a
                db isAlpha              ; b
                db isAlpha              ; c
                db isAlpha              ; d
                db isAlpha              ; e
                db isAlpha              ; f
                db isAlpha              ; g
                db isAlpha              ; h
                db isAlpha              ; i
                db isAlpha              ; j
                db isAlpha              ; k
                db isAlpha              ; l
                db isAlpha              ; m
                db isAlpha              ; n
                db isAlpha              ; o
                db isAlpha              ; p
                db isAlpha              ; q
                db isAlpha              ; r
                db isAlpha              ; s
                db isAlpha              ; t
                db isAlpha              ; u
                db isAlpha              ; v
                db isAlpha              ; w
                db isAlpha              ; x
                db isAlpha              ; y
                db isAlpha              ; z
                db retCh                ; {
                db maybeOrElse          ; |
                db retCh                ; }
                db retCh                ; ~
                db skipWS               ; DEL

if usePropChars
                include "PropChars.asm"
endif

KwIf            db "if", 0
KwEnd           db "end", 0
KwGoto          db "goto", 0
KwElse          db "else", 0
KwElif          db "elif", 0
KwFun           db "fun", 0
KwRet           db "ret", 0
KwInt           db "int", 0
KwInts          db "ints", 0
KwStr           db "str", 0
KwStrs          db "strs", 0
                db 0 ; End.

; We 'reuse' some of the char codes which do not stand for
; themselves here to represent other tokens.

TypeInt         equ $01                 ; There cannot be a type code 0!
TypeStr         equ $02
TypeArray       equ $08
TypeInts        equ TypeInt + TypeArray
TypeStrs        equ TypeStr + TypeArray
NonTypeBits     equ $f0
TypeLabel       equ $ff
TypeFunc        equ $fe
TypeProc        equ $fd
TypeVoid        equ $fc

TokEOF          equ $00
TokAndAlso      equ $81                 ; &&
TokOrElse       equ $82                 ; ||
TokLE           equ $83                 ; <=
TokGE           equ $84                 ; >=
TokNE           equ $85                 ; !=
TokNewID        equ $86
TokID           equ $87
TokIf           equ $88
TokEnd          equ $89
TokGoto         equ $90
TokElse         equ $91
TokElif         equ $92
TokFun          equ $93
TokRet          equ $94
TokInt          equ TypeInt
TokInts         equ TypeInts
TokStr          equ TypeStr
TokStrs         equ TypeStrs

DispFile        equ $4000
AttrFile        equ $5800
BlackInk        equ 0
BlackPaper      equ 0 * 8
BlueInk         equ 1
BluePaper       equ 1 * 8
RedInk          equ 2
RedPaper        equ 2 * 8
MagentaInk      equ 3
MagentaPaper    equ 3 * 8
GreenInk        equ 4
GreenPaper      equ 4 * 8
CyanInk         equ 5
CyanPaper       equ 5 * 8
YellowInk       equ 6
YellowPaper     equ 6 * 8
WhiteInk        equ 7
WhitePaper      equ 7 * 8
Bright          equ %01000000
Flash           equ %10000000
RomChars        equ $3d00

KindHL          equ 0                   ; Value is "in" the HL register.
KindCon         equ 1                   ; Constant.
KindVar         equ 2                   ; Variable.
KindStk         equ 3                   ; Value is "on" the stack.

CellSize        equ 7                   ; Src id ptr, type byte, var ptr, next ptr.

