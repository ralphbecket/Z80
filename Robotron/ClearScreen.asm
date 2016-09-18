; Clear screen.
;
; A: attr.

ClearScreen             ld hl, $4000
                        ld de, $4001
                        ld bc, $1800
                        ld (hl), l
                        ldir
                        ld bc, $02ff
                        ld (hl), a
                        ldir
                        ret
