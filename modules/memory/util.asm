	ifnd H_MEMORY_UTIL
H_MEMORY_UTIL = 1

	macro MemCopy
		move.w	\3, -(sp)
		move.l	\2, -(sp)
		move.l	\1, -(sp)
		jsr _MemCopy
		PopStack 10
	endm

; Copy the specified memory region.
; ss ss ss ss - Source address
; dd dd dd dd - Destination address
; nn nn - Number of bytes
_MemCopy:
	move.w	12(sp), d1
	subi.w	#1, d1

	move.l	4(sp), a0	; Source
	move.l	8(sp), a1	; Destination

_MemCopy_Loop:
	move.b 	(a0)+, (a1)+
	dbra	d1, _MemCopy_Loop
	rts

	endif