; A simple memory allocator.  Memory is allocated in fixed-sized cells
; from a free-list.  If the free-list is empty, it is allowed to acquire
; new memory up to a given limit.  The first word in each free cell is
; a pointer to the next free cell or 0 if this is the last cell in the
; chain.

; Alloc (- ; hl = ptr to new cell, ade = xxx)
;
Alloc           ld hl, (FreeList)

                ld a, h
                or l
                jp z, allocNew

                ld e, (hl)
                inc hl
                ld d, (hl)
                dec hl
                ld (FreeList), de

                ret

allocNew        ld hl, (FreeReached)
                push hl
                ld de, CellSize
                add hl, de
                ld (FreeReached), hl
                ld de, (FreeTop)
                and a
                sbc hl, de
                pop hl
                ret c                   ; The heap is not exhausted!
                halt                    ; The heap is exhausted!

; ResetHeap )
;
ResetHeap       ld hl, (FreeBase)
                ld (FreeReached), hl
                ret

