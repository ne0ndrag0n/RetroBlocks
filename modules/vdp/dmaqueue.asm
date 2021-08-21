	ifnd H_VDP_DMAQUEUE
H_VDP_DMAQUEUE = 1

	include 'modules/vdp/util.asm'
	include 'modules/helpers/debug.asm'

VDP_DMAQUEUE_START = $FF0016
VDP_DMAQUEUE_END   = $FF00A3
VDP_DMAQUEUE_QUEUED = VDP_DMAQUEUE_START
VDP_DMAQUEUE_ENTRIES = VDP_DMAQUEUE_QUEUED + 2
VDP_DMAQUEUE_ENTRY_SIZE = 14

; DMA queue format:
; xx xx - Amount of entries in the queue
; qq qq qq ... - Queued entries in the format below

; DMA queue entry format:
; lz lz uz uz - Longword to write lower then upper DMA size
; ls ls ms ms - Longword to write lower then middle source address
; us us - Word to write upper source addresss
; dd dd dd dd - Destination VDP control word
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
	; Find nearest 00 00 00 00 DMA amount but do not exceed VDP_DMAQUEUE_END
	move.l	#VDP_DMAQUEUE_ENTRIES, a0

DmaQueueEnqueue_Find:
	tst.l	(a0)
	beq.s	DmaQueueEnqueue_Found			; If we find a tombstone, this is a free DMA queue slot.

	add.l	#VDP_DMAQUEUE_ENTRY_SIZE, a0

	move.l	a0, d0
	cmpi.l	#VDP_DMAQUEUE_END, d0
	bhs.s	DmaQueueEnqueue_End				; If address is now past VDP_DMAQUEUE_END, there's no more room. Bail out.

	bra.s	DmaQueueEnqueue_Find			; Otherwise, keep looking

DmaQueueEnqueue_Found:
	move.l	a0, a1							; Save this really quick to return it

	DisableInterrupts						; Open a critical section

	move.l	#$93009400, (a0)				; Size template
	move.l	#$95009600, 4(a0)
	move.w	#$9700, 8(a0)					; Source address template

	move.l	6(sp), d0
	lsr.l	#1, d0
	move.l	d0, 6(sp)						; The source address must be shifted right by one

	move.b	5(sp), 1(a0)					; Lower byte of size
	move.b	4(sp), 3(a0)					; Upper byte of size
	move.b	9(sp), 5(a0)					; Lower byte of source
	move.b	8(sp), 7(a0)					; Middle byte of source
	move.b	7(sp), 9(a0)					; Upper byte of source

	move.l	10(sp), 10(a0)					; Write VDP control word

	addi.w	#1, VDP_DMAQUEUE_QUEUED			; Increment VDP_DMAQUEUE_QUEUED

	EnableInterrupts

	move.l	a1, d0							; Returning the address found in the queue
	rts

DmaQueueEnqueue_End:
	move.l	#0, d0
	rts

; Send items in the DMA queue.
DmaQueueExecute:
	btst	#0, SYSTEM_STATUS
	bne.s	DmaQueueEnqueue_End		; VDP_CONTROL is locked. We'll need to execute DMA next vblank.

	move.l	#VDP_DMAQUEUE_ENTRIES, a0

DmaQueueExecute_Loop:
	tst.w	VDP_DMAQUEUE_QUEUED
	beq.w	DmaQueueExecute_End		; If VDP_DMAQUEUE_QUEUED is 0, no more/nothing to do

	subi.w	#1, VDP_DMAQUEUE_QUEUED

DmaQueueExecute_ViewNext:
	tst.l	(a0)					; If this entry is 0, it's a tombstone so skip it
	bne.s	DmaQueueExecute_SendEntry

	add.l	#VDP_DMAQUEUE_ENTRY_SIZE, a0
	bra.s	DmaQueueExecute_ViewNext

DmaQueueExecute_SendEntry:
	move.l	(a0), VDP_CONTROL
	move.l	4(a0), VDP_CONTROL
	move.w	8(a0), VDP_CONTROL		; Send all preformatted commands to VDP DMA registers
	move.l	10(a0), VDP_CONTROL		; Send VDP control word, executing the DMA

	move.l	#0, (a0)				; Mark the entry as a tombstone by zeroing out the first two registers

	add.l	#VDP_DMAQUEUE_ENTRY_SIZE, a0		; Bump a0 to the next word
	bra.w	DmaQueueExecute_Loop

DmaQueueExecute_End:
	rts

	endif