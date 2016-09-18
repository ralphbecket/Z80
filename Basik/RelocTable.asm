; This is a table of references to runtime addresses
; in the code fragments used for code generation in the
; compiler.

RelocTable      dw RuntimeBase + 1
                dw eMulCode + 1
                dw eDivCode + 1
                dw pSetHeapBounds + 1
                dw rhTestBounds + 2
                dw rhTestBounds + 6
                dw 0            ; Done!
