                        zeusemulate "48K", "ULA+"
Zeus_PC                 equ TestSymTab
Zeus_SP                 equ $FF40
                        org $8000



TestSymTab              ld hl, tsSrc
                        ld (CurrSrcPtr), hl

tsNext                  call NextToken
                        call FindSym
                        jp z, tsMiss
                        jp (hl)

tsMiss                  halt



                        include "SymTab.asm"
                        include "Tokeniser.asm"

; Test data.
                        ds 1 + ($ff ^ (* & $ff))

tsSrc                   db " foo + (bar + foo )", 0

; Test symbol table.

SymTabLast              dw tsBarEntry

tsLPar                  db "("
tsRPar                  db ")"
tsAdd                   db "+"
tsFoo                   db "foo"
tsBar                   db "bar"

tsLParEntry             dw 0
                        db 1
                        dw tsLPar
                        jp tsNext       ; '('

tsRParEntry             dw tsLParEntry
                        db 1
                        dw tsRPar
                        jp tsNext       ; ')'

tsAddEntry              dw tsRParEntry
                        db 1
                        dw tsAdd
                        jp tsNext       ; '+'

tsFooEntry              dw tsAddEntry
                        db 3
                        dw tsFoo
                        jp tsNext       ; 'foo'

tsBarEntry              dw  tsFooEntry
                        db 3
                        dw tsBar
                        jp tsNext       ; 'bar'



