                        org $8000
                        zeusemulate "48K", "ULA+"
Zeus_PC                 equ TestTokeniser
Zeus_SP                 equ $FF40

TestTokeniser           ld hl, TestSrc
                        ld (CurrSrcPtr), hl

ttLoop                  call NextToken
                        jr ttLoop

TestSrc                 db "  this +> that(-257foo) ", 0

                        include "Tokeniser.asm"
