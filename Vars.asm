
scannedIDLastCh db 0                    ; Temp. when zeroing end of ID for symtab lookup.
haveSavedTok    db 0                    ; Non-zero when we have a saved token to serve.
savedTok        db 0                    ; The saved token, if any.
savedTokEntry   dw 0                    ; The saved token entry ptr, if any.

NextChPtr       dw 0                    ; Ptr to the next source char to read.
ScannedInt      dw 0                    ; The scanned int.
ScannedIDStart  dw 0                    ; Ptr to first char of scanned ID.
ScannedIDEnd    dw 0                    ; Ptr to one past last char of scanned ID.

CodeBase        dw $e000
CodePtr         dw $e000
CodeTop         dw $f000


if usePropChars
CharSet         dw PropChars - 256
else
CharSet         dw RomChars
endif
PutAttrPtr      dw AttrFile
PutAttr         db Bright + BlackInk + WhitePaper

GlobalSymTab    ds 256
LocalSymTab     ds 256

newBinOp        dw 0                    ; Temporary note of the new operator to be pushed.
kindHLPtr       dw 0                    ; 0 or the address of the KindHL entry on the stack.

binOpLValue     dw 0
binOpLTypeKind  equ *
binOpLKind      db 0
binOpLType      db 0

binOpRValue     dw 0
binOpRTypeKind  equ *
binOpRKind      db 0
binOpRType      db 0
ExprType        equ binOpRType

symTabIDPtr     dw 0

newEntryPtr     dw 0
newIDStart      dw 0
newIDEnd        dw 0
newVarPtr       dw 0
newVarType      db 0

FreeBase        dw $d000                ; The lowest address which can contain cells.
FreeTop         dw $e000                ; One above the highest address containing cells.
FreeReached     dw $d000                ; The lowest used address in the cell heap.
FreeList        dw 0                    ; The first free cell in the free list.

EndOfScopeTok   db 0                    ; The token scanned which caused an "end of scope".

