	ifnd H_HELPERS_SORT
H_HELPERS_SORT = 1

	macro Sort
		move.w	\2, -(sp)
		move.w	#0, -(sp) 	; alignment
		move.l	\1, -(sp)
		jsr		Shellsort
		PopStack 8
	endm

; Shellsort an array. The unit used is byte.
; aa aa aa aa - Address
; 00 00 ss ss - Size
Shellsort:
	SetupFramePointer
	move.l	a2, -(sp)
	move.l	a3, -(sp)
	move.l	a4, -(sp)
	move.l	d2, -(sp)

	cmpi.w	#2,	10(fp)
	blo		Shellsort_End	; nothing to do for items less than 2

	; while size != 0
	; 	divide size by 2
	;	for i = 0 to size - 1
	;		start = address + i
	;		cursor = start + size
	;		loop
	;			origin = cursor
	;			while cursor > start && *cursor < *(cursor - size)
	;				swap *cursor and *(cursor - size)
	;				cursor = cursor - size
	;			if origin + size < end
	;				cursor = origin + size
	;			else
	;				break

	move.l	4(fp), a2
	add.l	8(fp), a2				; a2 = end = address + size

Shellsort_While_SizeNot0:
	move.w	10(fp), d0
	lsr.w	#1, d0
	tst.w	d0
	beq		Shellsort_End			; while size != 0
	move.w	d0, 10(fp)				; size / 2

	move.l	#0, d1					; d1 = i = 0
Shellsort_OuterFor:
	move.l	4(fp), a1
	add.l	d1,	a1					; a1 = start = address + i

	move.l	a1, a0
	add.l	8(fp), a0				; a0 = cursor = start + size

Shellsort_OuterFor_Loop:
	move.l	a0, a3					; a3 = origin = cursor

Shellsort_OuterFor_Loop_While:
	cmp.l	a1, a0					; is cursor <= start? break
	bls		Shellsort_OuterFor_Loop_While_End

	sub.l	8(fp), a0
	move.b	(a0), d0
	add.l	8(fp), a0				; *(cursor - size)

	move.b	(a0), d2
	cmp.b	d0, d2					; if *cursor >= *(cursor - size)? break
	bhs		Shellsort_OuterFor_Loop_While_End

	sub.l	8(fp), a0
	move.b	d2, (a0)
	add.l	8(fp), a0
	move.b	d0, (a0)				; Swap values at *cursor and *(cursor - size)

Shellsort_OuterFor_Loop_While_End:
	move.l	a3, d0
	add.l	8(fp), d0				; origin + size
	cmp.l	a2, d0					; if origin + size >= end, break
	bhs		Shellsort_OuterFor_Loop_End

	move.l	d0, a0					; cursor = origin + size
	bra		Shellsort_OuterFor_Loop

Shellsort_OuterFor_Loop_End:
	addi.l	#1, d1					; i++
	move.l	8(fp), d0
	subi.l	#1, d0					; size - 1
	cmp.l	d0, d1
	bls		Shellsort_OuterFor		; Keep going if i <= size - 1

	bra		Shellsort_While_SizeNot0 ; Next iteration of the while loop

Shellsort_End:
	move.l	(sp)+, d2
	move.l	(sp)+, a4
	move.l	(sp)+, a3
	move.l	(sp)+, a2
	RestoreFramePointer
	rts

	endif