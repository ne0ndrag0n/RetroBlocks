	ifnd H_VDP_DMAQUEUE
H_VDP_DMAQUEUE = 1

	include 'modules/vdp/util.asm'
	include 'modules/helpers/debug.asm'

; DMA queue format:
; xx xx - Amount of entries in the queue
; qq qq qq ... - Queued entries in the format below

; DMA queue entry format:
; xx xx - DMA amount (bytes)
; aa aa aa aa - Source address
; aa aa aa aa - Destination VDP word (VRAM/CRAM/VSRAM)
; DMA formats of 0 marked eligible for reclamation

	macro VdpDmaQueueEnqueue
		move.l	\3, -(sp)
		move.l	\2, -(sp)
		move.w	\1, -(sp)
		jsr DmaQueueEnqueue
		PopStack 10
	endm

; Enqueue a DMA operation to be performed on next VBlank.
; xx xx - DMA amount (bytes)
; aa aa aa aa - Source address
; aa aa aa aa - Destination VDP control word (VRAM/CRAM/VSRAM)
; Returns: Pointer to the data in the DMA queue. DO NOT WRITE TO THIS! Use this to *test*
; the DMA amount if you need to block the application for loading.
DmaQueueEnqueue:
	; Find nearest 00 00 DMA amount but do not exceed VDP_DMAQUEUE_END
	move.l	#VDP_DMAQUEUE_ENTRIES, a0

DmaQueueEnqueue_Find:
	tst.w	(a0)
	beq.s	DmaQueueEnqueue_Found			; If we find a tombstone or a 00 00, this is a free DMA queue slot.

	add.l	#VDP_DMAQUEUE_ENTRY_SIZE, a0

	move.l	a0, d0
	cmpi.l	#VDP_DMAQUEUE_END, d0
	bhs.s	DmaQueueEnqueue_End				; If address is now past VDP_DMAQUEUE_END, there's no more room. Bail out.

	bra.s	DmaQueueEnqueue_Find			; Otherwise, keep looking

DmaQueueEnqueue_Found:
	move.l	a0, a1							; Save this really quick to return it

	move.w	4(sp), (a0)+
	move.l	6(sp), (a0)+
	move.l	10(sp), (a0)+					; Slot these items into the spot found in the DMA queue

	addi.w	#1, VDP_DMAQUEUE_QUEUED			; Increment VDP_DMAQUEUE_QUEUED

	move.l	a1, d0							; Returning the address found in the queue
	rts

DmaQueueEnqueue_End:
	move.l	#0, d0
	rts

; Send items in the DMA queue.
DmaQueueExecute:
	btst	#0, LOCK_STATUS
	bne.s	DmaQueueEnqueue_End		; VDP_CONTROL is locked. We'll need to execute DMA next vblank.

	move.l	#VDP_DMAQUEUE_ENTRIES, a0

DmaQueueExecute_Loop:
	tst.w	VDP_DMAQUEUE_QUEUED
	beq.w	DmaQueueExecute_End		; If VDP_DMAQUEUE_QUEUED is 0, no more/nothing to do

	subi.w	#1, VDP_DMAQUEUE_QUEUED

DmaQueueExecute_ViewNext:
	tst.w	(a0)					; If this entry is 0, it's a tombstone so skip it
	bne.s	DmaQueueExecute_SendEntry

	add.l	#VDP_DMAQUEUE_ENTRY_SIZE, a0
	bra.s	DmaQueueExecute_ViewNext

DmaQueueExecute_SendEntry:
	move.w	#$9300, d0
	move.b	1(a0), d0
	move.w	d0, VDP_CONTROL			; Write the lower dma size byte

	move.w	#$9400, d0
	move.b	(a0), d0
	move.w	d0, VDP_CONTROL			; Write the upper dma size byte

	move.w	#0, (a0)				; Mark as tombstone available for reuse

	; TODO: Detect dma copy/dma fill and handle appropriately
	; Does not currently work with dma copy/dma fill!

	move.l	2(a0), d0
	lsr.l	#1, d0
	move.l	d0, 2(a0)				; Format source address for registers (shift right 1)

	move.w	#$9500, d0
	move.b	5(a0), d0
	move.w	d0, VDP_CONTROL			; Write low byte

	move.w	#$9600, d0
	move.b	4(a0), d0
	move.w	d0, VDP_CONTROL			; Write middle byte

	move.w	#$9700, d0
	move.b	3(a0), d0
	move.w	d0, VDP_CONTROL			; Write high byte

	move.l	6(a0), VDP_CONTROL		; Send VDP control word, executing the DMA
	add.l	#VDP_DMAQUEUE_ENTRY_SIZE, a0		; Bump a0 to the next word
	bra.w	DmaQueueExecute_Loop

DmaQueueExecute_End:
	rts

	endif