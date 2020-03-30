	ifnd H_DIFF_CHUNK
H_DIFF_CHUNK = 1

	include 'modules/helpers/stack.asm'

; Determine if two coordinate triplets fall within the same diff chunk
; If x, y, and z divided by CHUNK_SIZE are the same for both triplets,
; they are in the same chunk.
; x1 y1
; 00 z1
; x2 y2
; 00 z2
; Returns: 00 re
;             re - 0 if false, 1 if true
IsSameChunk:
	SetupFramePointer
	Allocate #2

	move.w	#0, d0
	move.b  4(fp), d0
	divu.w  #CHUNK_SIZE, d0		; x1 / CHUNK_SIZE
	move.w	d0, (sp)			; Push it

	move.w  #0, d0
	move.b  8(fp), d0
	divu.w  #CHUNK_SIZE, d0     ; x2 / CHUNK_SIZE

	cmp.w   (sp), d0
	bne.s   IsSameChunk_False

	move.w	#0, d0
	move.b  5(fp), d0
	divu.w  #CHUNK_SIZE, d0		; y1 / CHUNK_SIZE
	move.w	d0, (sp)			; Push it

	move.w  #0, d0
	move.b  9(fp), d0
	divu.w  #CHUNK_SIZE, d0     ; y2 / CHUNK_SIZE

	cmp.w   (sp), d0
	bne.s   IsSameChunk_False

	move.w	#0, d0
	move.b  7(fp), d0
	divu.w  #CHUNK_SIZE, d0		; z1 / CHUNK_SIZE
	move.w	d0, (sp)			; Push it

	move.w  #0, d0
	move.b  11(fp), d0
	divu.w  #CHUNK_SIZE, d0     ; z2 / CHUNK_SIZE

	cmp.w   (sp), d0
	bne.s   IsSameChunk_False

IsSameChunk_True:
	move.w	#1, d0
	bra.s   IsSameChunk_Finally

IsSameChunk_False:
	move.w  #0, d0

IsSameChunk_Finally:
	Deallocate #2
	RestoreFramePointer
	rts


	endif