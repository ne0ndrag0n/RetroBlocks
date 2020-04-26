	ifnd H_MATH_HASH
H_MATH_HASH = 1


	macro MathPearsonHash
		move.w	\2, -(sp)
		move.l	\1, -(sp)
		jsr	PearsonHash
		PopStack 6
	endm

; Given a stream of bytes and a length, compute the 8-bit Pearson hash for the sequence.
; aa aa aa aa - Address to stream of bytes
; 00 ll - Length of sequence
; Returns: 00 hh - Pearson hash for the sequence.
PearsonHash:
	move.l	d2, -(sp)

	move.l	4+4(sp), a0						; a0 = address of sequence ("key")
	move.l	#PearsonHashLookupTable, a1		; a1 = address of lookup table ("T")
	move.w	4+8(sp), d1						; d1 = length of sequence
	subi.w	#1, d1

	move.w	d1, d0							; d0 (hash) = d1

PearsonHash_Loop:
	move.b	(a0, d1), d2
	eor.b	d0, d2							; d2 = hash ^ key[--i]

	move.b	(a1, d2), d0					; d0 = T[hash ^ key[--i]]

	dbeq	d1, PearsonHash_Loop			; --i

	move.l	(sp)+, d2
	rts

	endif