
; Gen (hl = src, bc = length; de = ptr to code byte after addition)
;
Gen             push hl
                ld hl, (CodePtr)
                push hl
                add hl, bc
                ld de, (CodeVars)       ; Don't crash into the vars!
                and a
                sbc hl, de
                jp nc, gOutOfMemory
                pop de
                pop hl
                ldir
                ld (CodePtr), de
                ret

gOutOfMemory    halt

GenRet          ld hl, (CodePtr)
                ld (hl), $c9            ; $c9 = 'ret'
                inc hl
                ld (CodePtr), hl
                ret

ResetGen        ld hl, (CodeBase)
                ld (CodePtr), hl
                ld hl, (CodeTop)
                ld (CodeVars), hl
                ret

; GenVar (a = type; hl = ptr to var).
;
GenVar          ld hl, (CodeVars)
                dec hl
                ld (hl), a
                dec hl
                dec hl
                ld (CodeVars), hl
                ld de, (CodePtr)
                and a
                sbc hl, de
                jp c, gOutOfMemory
                ld hl, (CodeVars)
                inc hl
                ret

