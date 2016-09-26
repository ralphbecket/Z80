; This is the XABC algorithm.
; I use the alternate register set for speed.
; Prime with InitRnd.asm.

Rnd                     exx
                        inc b           ; b = b + 1
                        ld a, b
                        xor c
                        xor e
                        ld c, a         ; c = b ^ c ^ e
                        add a, d
                        ld d, a         ; d = c + d
                        rrca
                        xor c
                        add a, e
                        ld e, a         ; e = (d/2) ^ c + e
                        exx
                        ret
