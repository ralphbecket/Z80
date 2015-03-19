; This implementation uses a character-properties table.

Scan            ld a, (haveSavedTok)
                and a
                jp z, scanTok

                xor a                   ; We have a "saved" token (via UnScan).
                ld (haveSavedTok), a
                ld a, (ScannedTok)
                cp TokNewID
                jp z, lookupID          ; This may have been added since last time.
                ld hl, (ScannedSymEntry)
                ret

scanTok         ld hl, ScanCharProps
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
                ld (ScannedTok), a
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
                ld (ScannedTok), a
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

lookupID        ld hl, (ScannedIDEnd)
                ld a, (hl)
                ld (scannedIDLastCh), a
                ld (hl), 0
                ld de, (ScannedIDStart)
                ld hl, GlobalSymTab     ; XXX More to go here!
                call FindSym
                ld (ScannedSymEntry), hl
                ld a, (scannedIDLastCh)
                ld de, (ScannedIDEnd)
                ld (de), a
                ld a, TokID
                ld (ScannedTok), a
                ret z
                ld a, TokNewID
                ld (ScannedTok), a
                ret

notASCII        di
                halt ; This isn't plain ASCII!

UnScan          ld a, 1
                ld (haveSavedTok), a
                ret

ResetScan       xor a
                ld (haveSavedTok), a
                ret



