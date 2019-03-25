; Sprites.asm

MaxSprites      equ 16  ; I think we'll only need five or six.

; Sprite control data structure.

SpriteTimer             equ 0
SpriteTimerDec          equ 1
SpriteTimerRst          equ 2
SpriteDir               equ 3
SpriteMazeAddrLo        equ 4  ; The top-left of the sprite is at this maze addr.
SpriteMazeAddrHi        equ 5
SpriteBackAddrLo        equ 6  ; The 3x3 background store buffer addr.
SpriteBackAddrHi        equ 7
SpriteImgAddrLo         equ 8  ; The addr of the 3x3 image for the sprite.
SpriteImgAddrHi         equ 9

SpriteDataSize          equ 10

; Sprite directions.

East            equ 0
South           equ 1
West            equ 2
North           equ 3

; Call the routine in HL for each sprite in turn, with IX pointing
; to the corresponding sprite data block on each call.
; (Higher order machine code!)
;
DoSprites proc
        ld (_Smc + 1), HL
        ld A, (NumSprites)
        ld IX, SpriteData
        push AF
_1      pop AF
        and A
        ret z
        dec A
        push AF
_Smc    call 00
        ld BC, SpriteDataSize
        add IX, BC
        jr _1
endp

; Copy a 3x3 region of draw calls from the maze to a linear buffer.
; HL is the addr of the top left cell of the sprite in the Maze;
; DE is the addr of the linear buffer.
;
Copy3x3FromMaze proc
        ld A, L
        for ii = 1 to 3
                ; Copy 3 cells in a row.
                ldi
                ldi
                ldi
                ldi
                ldi
                ldi
                ; Adjust HL to point to the next maze row.
                if ii < 3
                        ld L, A
                        inc H
                endif
        next
        ret
endp

; Copy a 3x3 region of draw calls to the maze to a linear buffer.
; DE is the addr of the top left cell of the sprite in the Maze;
; HL is the addr of the linear buffer.
;
Copy3x3ToMaze proc
        ld A, E
        for ii = 1 to 3
                ; Copy 3 cells in a row.
                ldi
                ldi
                ldi
                ldi
                ldi
                ldi
                ; Adjust DE to point to the next maze row.
                if ii < 3
                        ld E, A
                        inc D
                endif
        next
        ret
endp

; Update all the sprites.
;
UpdateSprites proc

        ld HL, RestoreBg
        call DoSprites

        ld HL, MoveSprite
        call DoSprites

        ld HL, SaveBg
        call DoSprites

        ; This doesn't actually draw the sprite, it just
        ; changes the corresponding maze entries to point
        ; to the sprite cell drawing routines.
        ld HL, DrawSprite
        call DoSprites

        ret

        RestoreBg proc
                ld L, (IX + SpriteBackAddrLo)
                ld H, (IX + SpriteBackAddrHi)
                ld E, (IX + SpriteMazeAddrLo)
                ld D, (IX + SpriteMazeAddrHi)
                jp Copy3x3ToMaze
        endp

        SaveBg proc
                ld L, (IX + SpriteMazeAddrLo)
                ld H, (IX + SpriteMazeAddrHi)
                ld E, (IX + SpriteBackAddrLo)
                ld D, (IX + SpriteBackAddrHi)
                jp Copy3x3FromMaze
        endp

        DrawSprite proc
                ld L, (IX + SpriteImgAddrLo)
                ld H, (IX + SpriteImgAddrHi)
                ld E, (IX + SpriteMazeAddrLo)
                ld D, (IX + SpriteMazeAddrHi)
                jp Copy3x3ToMaze
        endp

        MoveSprite proc

                ; See if it's time to move.
                ld a, (IX + SpriteTimer)
                sub (IX + SpriteTimerDec)
                jr c, _Move

        _NoMove ld (IX + SpriteTimer), A
                ret ; Don't move this frame.

        _Move   add (IX + SpriteTimerRst)
                ld (IX + SpriteTimer), A
                ; See if we need to change direction.
                ld L, (IX + SpriteMazeAddrLo)
                ld H, (IX + SpriteMazeAddrHi)
                ld A, (HL)
                cp 16 ; Low-byte addresses 0..15 are reserved for junction points.
                jr nc, _Go

        _ChDir  add A, A
                add A, A
                add (IX + SpriteDir)
                ld E, A
                ld D, high(JunctionExitsTable)
                ld A, (DE)
                ; At this point A contains four valid exit directions.
                ld B, A
                ld A, R ; I'm calling this a random number :-)
                rrca
                jr c, _1
                srl B
                srl B
                srl B
                srl B
        _1      rrca
                jr c, _2
                srl B
                srl B
        _2      ld A, B
                and $03
                ld (IX + SpriteDir), A

        _Go     ld A, (IX + SpriteDir) ; 0123 are ESWN.
                rrca
                jr c, _GoNS

        _GoEW   inc L
                inc L
                rrca
                jr nc, _Gone
                dec L
                dec L
                dec L
                dec L
                jr _Gone

        _GoNS   inc H
                rrca
                jr nc, _Gone
                dec H
                dec H

        _Gone   ld (IX + SpriteMazeAddrLo), L
                ld (IX + SpriteMazeAddrHi), H
                ret
        endp

endp

InitSprites proc


        ; Red Ghost.
        ld IX, RedSpriteData
        ld (IX + SpriteTimer), 1
        ld (IX + SpriteTimerDec), 100
        ld (IX + SpriteTimerRst), 100
        ld (IX + SpriteDir), West
        ld HL, Maze + $1534
        ld DE, RedBackSpace
        ld (IX + SpriteMazeAddrLo), L
        ld (IX + SpriteMazeAddrHi), H
        ld (IX + SpriteBackAddrLo), E
        ld (IX + SpriteBackAddrHi), D
        call Copy3x3FromMaze
        ld (IX + SpriteImgAddrLo), low(RedGhostImg)
        ld (IX + SpriteImgAddrHi), high(RedGhostImg)

        ; Cyan Ghost.
        ld IX, CyanSpriteData
        ld (IX + SpriteTimer), 1
        ld (IX + SpriteTimerDec), 100
        ld (IX + SpriteTimerRst), 100
        ld (IX + SpriteDir), East
        ld HL, Maze + $1534
        ld DE, CyanBackSpace
        ld (IX + SpriteMazeAddrLo), L
        ld (IX + SpriteMazeAddrHi), H
        ld (IX + SpriteBackAddrLo), E
        ld (IX + SpriteBackAddrHi), D
        call Copy3x3FromMaze
        ld (IX + SpriteImgAddrLo), low(CyanGhostImg)
        ld (IX + SpriteImgAddrHi), high(CyanGhostImg)

        ; Magenta Ghost.
        ld IX, MagentaSpriteData
        ld (IX + SpriteTimer), 1
        ld (IX + SpriteTimerDec), 100
        ld (IX + SpriteTimerRst), 100
        ld (IX + SpriteDir), West
        ld HL, Maze + $1534
        ld DE, MagentaBackSpace
        ld (IX + SpriteMazeAddrLo), L
        ld (IX + SpriteMazeAddrHi), H
        ld (IX + SpriteBackAddrLo), E
        ld (IX + SpriteBackAddrHi), D
        call Copy3x3FromMaze
        ld (IX + SpriteImgAddrLo), low(MagentaGhostImg)
        ld (IX + SpriteImgAddrHi), high(MagentaGhostImg)

        ; Green Ghost.
        ld IX, GreenSpriteData
        ld (IX + SpriteTimer), 1
        ld (IX + SpriteTimerDec), 100
        ld (IX + SpriteTimerRst), 100
        ld (IX + SpriteDir), East
        ld HL, Maze + $1534
        ld DE, GreenBackSpace
        ld (IX + SpriteMazeAddrLo), L
        ld (IX + SpriteMazeAddrHi), H
        ld (IX + SpriteBackAddrLo), E
        ld (IX + SpriteBackAddrHi), D
        call Copy3x3FromMaze
        ld (IX + SpriteImgAddrLo), low(GreenGhostImg)
        ld (IX + SpriteImgAddrHi), high(GreenGhostImg)

        ; XXX Other ghosts!

        ld A, 4
        ld (NumSprites), A

        ret

endp

GhostDrawing macro(colour)

        dw DrawEye, DrawEye, Ghost02
        dw Ghost10, Ghost11, Ghost12
        dw Ghost20, Ghost21, Ghost22

Ghost00 DrawBitmap(Bright + colour, $00, $07, $1f, $3f, $3f, $3f, $3f, $7f)
Ghost01 DrawAttr(Bright + colour + (colour << 3))
Ghost02 DrawBitmap(Bright + colour, $00, $e0, $f8, $fc, $fc, $fc, $fc, $fe)
Ghost10 DrawBitmap(Bright + colour, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f)
Ghost11 DrawAttr(Bright + colour + (colour << 3))
Ghost12 DrawBitmap(Bright + colour, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fe)
Ghost20 DrawBitmap(Bright + colour, $7f, $7f, $7f, $7f, $7f, $71, $60, $40)
Ghost21 DrawBitmap(Bright + colour, $ff, $ff, $ff, $ff, $ff, $f1, $e0, $40)
Ghost22 DrawBitmap(Bright + colour, $fe, $fe, $fe, $fe, $fe, $f2, $e0, $40)

endm

DrawEye DrawBitmap(Bright + White,  $3c, $7e, $ff, $ff, $0f, $0f, $0e, $0c)

; Yes, this is quite wasteful.  But this whole program is a proof of concept.

RedGhostImg     GhostDrawing(Red)
CyanGhostImg    GhostDrawing(Cyan)
MagentaGhostImg GhostDrawing(Magenta)
GreenGhostImg   GhostDrawing(Green)

NumSprites      db 0
SpriteData      equ $
RedSpriteData   ds SpriteDataSize
CyanSpriteData  ds SpriteDataSize
MagentaSpriteData ds SpriteDataSize
GreenSpriteData ds SpriteDataSize
RedBackSpace    ds 3 * 3 * 2
CyanBackSpace   ds 3 * 3 * 2
MagentaBackSpace ds 3 * 3 * 2
GreenBackSpace  ds 3 * 3 * 2



