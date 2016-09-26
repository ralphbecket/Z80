


; Add b to d and c to e unless doing so puts d outside 0..61
; or e outside 0..45, in which case NC flag is set on return.

Move                    ld a, e
                        add a, c
                        cp 62
                        ret nc
                        ld e, a
                        ld a, d
                        add a, b
                        cp 46
                        ret nc
                        ld d, a
                        ret

