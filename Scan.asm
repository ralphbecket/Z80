; This implementation uses a character-properties table.

Scan            proc

profile = true

                ld a, (haveSavedTok)
                and a
                jp z, scanTok

                xor a                   ; We have a "saved" token (via UnScan).
                ld (haveSavedTok), a
                ld a, (savedTok)
                ret

scanTok         ld hl, CharProps
                ld d, 0
                ld bc, (NextChPtr)
lp              ld a, (bc)
                cp 128
                jp nc, notASCII
                inc bc

                ld e, a                 ; Lookup the char table.
                add hl, de
                ld a, (hl)
                sbc hl, de

                ld (dispatch + 1), a    ; SMC!
dispatch        jr *                    ; SMC!
dispatchFrom    equ *

skipWS          equ lp - dispatchFrom   ; Jump backwards!

retCh           equ * - dispatchFrom
                ld (NextChPtr), bc
                ld a, e
                ret

maybeAndAlso    equ * - dispatchFrom    ; & or &&?
                ld hl, 256 * TokAndAlso + '&'
                jr maybeX

maybeOrElse     equ * - dispatchFrom    ; | or ||?
                ld hl, 256 * TokOrElse + '|'
                jr maybeX

maybeLE         equ * - dispatchFrom    ; < or <=?
                ld hl, 256 * TokLE + '='
                jr maybeX

maybeGE         equ * - dispatchFrom    ; > or >=?
                ld hl, 256 * TokGE + '='
                jr maybeX

maybeNE         equ * - dispatchFrom    ; ! or !=?
                ld hl, 256 * TokNE + '='
                jr maybeX

maybeX          ld a, (bc)
                cp l
                ld a, e
                ld (NextChPtr), bc
                ret nz
                ld a, h
                inc bc
                ld (NextChPtr), bc
                ret

isDigit         equ * - dispatchFrom
                ld a, e
                sub '0'
                ld l, a
                ld h, 0

intLp           ld a, (bc)
                sub '0'
                jp c, intDone
                cp 10
                jp nc, intDone
                inc bc
                add hl, hl              ; hl = 10.hl = 8.hl + 2.hl
                ld d, h
                ld e, l
                add hl, hl
                add hl, hl
                add hl, de
                ld e, a
                ld d, 0
                add hl, de              ; hl = hl + digit
                jp intLp

intDone         ld (NextChPtr), bc
                ld (ScannedInt), hl
                ld a, TokInt
                ret

isAlpha         equ * - dispatchFrom
                dec bc
                ld (ScannedIDStart), bc

idLp            inc bc
                ld a, (bc)
                ld e, a
                add hl, de
                ld a, (hl)
                sbc hl, de
                cp isAlpha
                jp z, idLp
                cp isDigit
                jp z, idLp

                ld (ScannedIDEnd), bc
                ld (NextChPtr), bc

                ld hl, (ScannedIDEnd)
                ld a, (hl)
                ld (scannedIDLastCh), a
                ld (hl), 0
                ld de, (ScannedIDStart)
                ld hl, GlobalSymTab     ; XXX More to go here!
                call FindSym
                ld a, (scannedIDLastCh)
                ld de, (ScannedIDEnd)
                ld (de), a
                ld a, TokID
                ret z
                ld a, TokNewID
                ret

notASCII        di
                halt ; This isn't plain ASCII!

profile = false

CharProps       db retCh                ; 0 = EOF.
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

                endp

UnScan          ld (savedTok), a
                ld a, 1
                ld (haveSavedTok), a
                ret

ResetScan       xor a
                ld (haveSavedTok), a
                ret

                if debug                ; ---- DEBUGGING CODE ----

; PutTok(a = token)
;
PutTok          proc

                ld (rememberTok + 1), a ; SMC!
                ld a, '['
                call PutCh
                ld hl, tokNames

lp              ld a, (hl)
                inc hl
rememberTok     cp 0                    ; SMC!
                jp z, found
                cp $ff                  ; Check for done.
                jp z, notFound

skipName        ld a, (hl)
                inc hl
                and a
                jp nz, skipName

                jp lp

notFound        ld a, (rememberTok + 1)
                call PutCh              ; This is a 'stands for itself' token.
                jp finish

found           call PutStr
                ld a, (rememberTok + 1)

                cp TokInt
                jp nz, notTokInt

                ld hl, (ScannedInt)
                call PutUInt
                jp finish

notTokInt       cp TokNewID
                jp nz, finish

                ld de, (ScannedIDStart)
                ld hl, (ScannedIDEnd)
                sbc hl, de
                ex de, hl
                call PutStrN

finish          ld a, ']'
                call PutCh
                ret

                endp

tokNames        db 0, "EOF", 0
                db TokAndAlso, "&&", 0
                db TokOrElse, "||", 0
                db TokLE, "<=", 0
                db TokGE, ">=", 0
                db TokNE, "!=", 0
                db TokInt, "int ", 0
                db TokNewID, "id ", 0
                db $ff

                endif                   ; ---- END OF DEBUGGING CODE ----

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
TokInt          equ TypeInt
TokInts         equ TypeInts
TokStr          equ TypeStr
TokStrs         equ TypeStrs

scannedIDLastCh db 0                    ; Temp. when zeroing end of ID for symtab lookup.
haveSavedTok    db 0                    ; Non-zero when we have a saved token to serve.
savedTok        db 0                    ; The saved token, if any.

NextChPtr       dw 0                    ; Ptr to the next source char to read.
ScannedInt      dw 0                    ; The scanned int.
ScannedIDStart  dw 0                    ; Ptr to first char of scanned ID.
ScannedIDEnd    dw 0                    ; Ptr to one past last char of scanned ID.

