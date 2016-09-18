; Fix all references to runtime addresses so they match once we
; copy the runtime system to the start of the generated code.

Reloc           ld hl, (CodeBase)
                ld de, RuntimeBase
                xor a
                sbc hl, de
                ld (rRelocDelta), hl
                call rReloc

                ld hl, RuntimeBase
                ld bc, RuntimeLength
                call Gen
                ret

rReloc          ld (rSavedSP), sp
                ld sp, RelocTable
                ld b, h
                ld c, l

rLp             pop hl
                ld a, h
                or l
                jp z, rDone
                ld e, (hl)
                inc hl
                ld d, (hl)
                ex de, hl
                xor a
                add hl, bc
                ex de, hl
                ld (hl), d
                dec hl
                ld (hl), e
                jp rLp

rDone           ld sp, (rSavedSP)
                ret

; Reset references to runtime addresses after relocation in
; case we want to re-run the compiler.

UnReloc         ld de, (rRelocDelta)
                ld hl, 0
                xor a
                sbc hl, de
                call rReloc

                ld hl, 0
                ld (rRelocDelta), hl
                ret

RuntimeBase     jp RuntimeEnd

; hl = hl * de
rMul            ld a, h
                ld c, l
                ld b, 16
rMulLp          add hl, hl
                sla c
                rla
                jr nc, rMulNoAdd
                add hl, de
rMulNoAdd       djnz rMulLp
                ret

; hl = de / hl
rUDiv           xor a
                jr rDiv2
rDiv            push de
                ex de, hl
                xor a
                bit 7, d
                jr z, rDiv1
                cpl
                ld hl, 0
                sbc hl, de
                ex de, hl
rDiv1           pop bc
                bit 7, b
                jr z, rDiv2
                cpl
                and a
                ld hl, 0
                sbc hl, bc
                ld b, h
                ld c, l
rDiv2           push af
                ld a, b
                ld hl, 0
                ld b, 16
rDivLp          rl c
                rla
                adc hl, hl
                sbc hl, de
                jr nc, rDivEndLp
                add hl, de
rDivEndLp       ccf
                djnz rDivLp
rDivDone        rl c
                rla
                ld h, a
                ld l, c
                pop af
                and a
                ret z
                ex de, hl
                ld hl, 0
                xor a
                sbc hl, de
                ret

; The runtime heap is a contiguous region of cells of the form
;       db cellType
;       dw forGC
;       dw numBytesInPayload
;       db payload, ...
; Vars point to the lengthInBytes field.
;
; Note that zero length payloads are always represented by $0000
; pointers - they are not allocated on the heap.
;
; When allocation hits the heap top, the garbage collector is run.
; The forGC field is used to link variables pointing to this heap
; cell during the marking pass.  Then the live heap cells are
; condensed into a contiguous region from the heap bottom and the
; forGC chains are used to update the referring variables.

; rHeapAlloc(a = type, hl = num; hl = ptr).
rHeapAlloc      ld b, a
                ld a, h
                or l
                ret z           ; Zero length structures are returned as null ptrs.
                ld a, b

                cp TypeStr
                jp nz, rhTestBounds
                add hl, hl      ; If it's not a string, each element is two bytes.
rhTestBounds    ld de, (rHeapPtr)
                ld bc, (rHeapTop)
                push hl
                push de         ; Stack = [rHeapPtr, payloadBytes, ...]
                inc hl
                inc hl
                inc hl
                inc hl
                inc hl
                add hl, de
                push hl         ; Stack = [newRHeapPtr, rHeapPtr, payloadBytes, ...]
                and a
                sbc hl, bc
                jr nc, rhGC
rhAllocCell     pop hl
                ld (rHeapPtr), hl       ; Stack = [rHeapPtr, payloadBytes, ...]
                pop hl          ; hl = rHeapPtr.
                pop bc          ; bc = payloadBytes, Stack = [...]
                ld (hl), a      ; Set the cellType field.
                xor a
                inc hl
                ld (hl), a      ; Clear the forGC field.
                inc hl
                ld (hl), a
                inc hl
                push hl         ; Stack = [numBytesInPayloadPtr, ...]
                ld (hl), c      ; Set the numBytesInPayload field.
                inc hl
                ld (hl), b
                inc hl
                ld (hl), a
                ld d, h
                ld e, l
                inc de
                dec bc
                ldir            ; Zero the payload.
                pop hl          ; hl = numBytesInPayloadPtr, Stack = [...]
                ret

rhGC            halt            ; XXX Fill this in! (N.B.: stuff is on the stack here.)

rHeapBot        dw 0            ; The lowest address in the heap.
rHeapPtr        dw 0            ; The first free address in the heap.
rHeapTop        dw 0            ; Invariant: rHeapPtr < rHeapTop.

                ; ...
RuntimeEnd      equ $
RuntimeLength   equ RuntimeEnd - RuntimeBase
