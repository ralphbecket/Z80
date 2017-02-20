UpKey                   equ "Q"
DownKey                 equ "A"
LeftKey                 equ "O"
RightKey                equ "P"

UpKeyBitNo              equ 3
DownKeyBitNo            equ 2
LeftKeyBitNo            equ 1
RightKeyBitNo           equ 0

; Test the keyboard to see what is pressed.
; The corresponding bits are set in D, A, and (CurrentKeys).
;
Keyboard                ld d, 0

kbTestUp                ld bc, zeuskeyaddr(UpKey)
                        in a, (c)
                        and zeuskeymask(UpKey)
                        jr z, kbTestDown
                        set UpKeyBitNo, d

kbTestDown              ld bc, zeuskeyaddr(DownKey)
                        in a, (c)
                        and zeuskeymask(DownKey)
                        jr z, kbTestLeft
                        set DownKeyBitNo, d

kbTestLeft              ld bc, zeuskeyaddr(LeftKey)
                        in a, (c)
                        and zeuskeymask(LeftKey)
                        jr z, kbTestRight
                        set LeftKeyBitNo, d

kbTestRight             ld bc, zeuskeyaddr(RightKey)
                        in a, (c)
                        and zeuskeymask(RightKey)
                        jr z, kbTestDone
                        set RightKeyBitNo, d

kbTestDone              ld a, d
                        ld (CurrentKeys), a
                        ret

CurrentKeys             db 0


