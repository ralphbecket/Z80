
scannedIDLastCh db 0                    ; Temp. when zeroing end of ID for symtab lookup.
haveSavedTok    db 0                    ; Non-zero when we have a saved token to serve.

NextChPtr       dw 0                    ; Ptr to the next source char to read.
ScannedInt      dw 0                    ; The scanned int.
ScannedIDStart  dw 0                    ; Ptr to first char of scanned ID.
ScannedIDEnd    dw 0                    ; Ptr to one past last char of scanned ID.
ScannedTok      db 0
ScannedSymEntry dw 0

CodeBase        dw $e000
CodePtr         dw $e000
CodeTop         dw $f000

if usePropChars
CharSet         dw PropChars
PutPropX        db 0
else
CharSet         dw RomChars
endif
PutAttrPtr      dw AttrFile
PutAttr         db Bright + BlackInk + WhitePaper

GlobalSymTab    ds 256
LocalSymTab     ds 256

eAndOrChain     dw 0                    ; Chain of &&/|| jump addr ptrs.
eAndOrCode      dw 0                    ; The &&/|| code is parameterised via this.

eNewBinOp       equ *                   ; Temporary note of the new operator to be pushed.
eNewBinOpIdx    db 0
eNewBinOpPrec   db 0
eKindHLPtr      dw 0                    ; 0 or the address of the KindHL entry on the stack.
eOpTblEntryPtr  dw 0

eLValue         dw 0
eLTypeKind      equ *
eLKind          db 0
eLType          db 0

eRValue         dw 0
eRTypeKind      equ *
eRKind          db 0
eRType          db 0

eLRKinds        db 0

ExprType        equ eRType

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

