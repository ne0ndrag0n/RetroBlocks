    ifnd H_MEMORY_HEAP
H_MEMORY_HEAP = 1

HEAP = $FF5000
HEAP_SIZE = 1024

    macro HeapAllocate
        move.w  \1, -(sp)
        jsr AllocateHeap
        PopStack 2
    endm

    macro HeapFree
        move.l  \1, -(sp)
        jsr FreeHeap
        PopStack 4
    endm

; Structure of a heap metadata object
; txxx xxxx xxxx xxxx
; Where "t" is the tombstone flag (ready to be reclaimed)
; and "x" is a size between 1 and 32767
; (will not fit heap if size is greater than HEAP_SIZE)

; Mark first block as tombstoned and (HEAP_SIZE - 2)
; This obviously invalidates anything currently in the heap and you're a dumbass
; if you don't invalidate all open pointers before calling this.
    macro HeapInit
        move.w	#$8000, HEAP				        ; Tombstoned, size 0
        ori.w	#(HEAP_SIZE - 2), HEAP		        ; Overlay the heap size onto d0
    endm

; Heap allocate
; bb bb - Number of bytes to allocate
; Returns:
; pp pp pp pp - Pointer to data. Null if could not allocate.
AllocateHeap:
    ; Validate parameter
    tst.w	4(sp)
    beq.s	AllocateHeap_ReturnNull		        ; Cannot allocate 0 bytes

    move.l  #0, d0
    move.w  4(sp), d0
    cmpi.l	#(HEAP_SIZE - 2), d0
    bhs.s	AllocateHeap_ReturnNull		        ; Cannot ever allocate greater than
                                                ; HEAP_SIZE - 2 bytes

    btst    #0, 5(sp)
    beq.s   AllocateHeap_IsAligned              ; Test for alignment - allocations must be even

    add.w   #1, 4(sp)                           ; If unaligned, make value even

AllocateHeap_IsAligned:
    ; Now look for the nearest tombstoned value that fits
    move.l	#HEAP, a0

AllocateHeap_FindFirstFit:
    btst 	#7, (a0)					        ; Tombstone?
    beq.s   AllocateHeap_FindFirstFit_Next      ; Skip to next if this block is active

    move.w  (a0), d0                            ; Now need to check if it fits
    andi.w  #$7FFF, d0                          ; d0 is now available space in this candidate chunk
    cmp.w   4(sp), d0                           ; Is the available space greater or equal to desired space?
    blo.s   AllocateHeap_FindFirstFit_Next

    ; One more check is required - if subdivision is required, is there room to divide the chunk?
    move.w  d0, d1
    sub.w   4(sp), d1                           ; Subtract desired amount from amount in chunk
    beq.s   AllocateHeap_FindFirstFit_UseBlock  ; If that just resulted in a zero there is no subdivision required

    cmpi.w  #4, d1                              ; Must be at least metadata size + 2 byte left over
    blo.s   AllocateHeap_FindFirstFit_Next

    ; Split the current block
    ; d0 = target block size, 4(sp) = desired block size, d1 = remaining size after use
    move.l  #0, a1                              ; Going to copy a0 to a1
    move.w  4(sp), a1                           ; add desired block size
    add.l   #2, a1                              ; add 2 to skip over current metadata
    add.l   a0, a1                              ; add original a0 address

    move.w  #$8000, (a1)                        ; Write tombstoned value to a1
    subi.w  #2, d1                              ; Remaining space won't include metadata
    or.w    d1, (a1)                            ; Overlay remaining space onto the segmented block

AllocateHeap_FindFirstFit_UseBlock:
    move.w  4(sp), (a0)                         ; Set the new block size to (a0) and clear tombstone flag
    bra.s   AllocateHeap_ReturnValue            ; Early return

AllocateHeap_FindFirstFit_Next:
    ; Did not find a value so keep going
    move.l  #0, d0
    move.w  (a0), d0                            ; Move current metadata into d0
    andi.w  #$7FFF, d0                          ; Erase tombstone value
    addi.w  #2, d0
    add.l   d0, a0                              ; Increment a0 past the metadata and current block

    cmp.l   #(HEAP + HEAP_SIZE), a0
    blo.s   AllocateHeap_FindFirstFit           ; Find next first fit if we didn't just overshoot heap

AllocateHeap_ReturnNull:
    move.l	#0, d0
    rts

AllocateHeap_ReturnValue:
    move.l  a0, d0
    addi.l  #2, d0                              ; Move a0 into return register and advance it past the metadata
    rts

; Given the pointer, free the data.
; pp pp pp pp - Pointer to free
FreeHeap:
    move.l  4(sp), a0
    sub.l   #2, a0                              ; Navigate to metadata directly behind pointer
    ori.w   #$8000, (a0)                        ; Set tombstone flag for this segment
    rts

    endif