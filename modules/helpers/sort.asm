	ifnd H_HELPERS_SORT
H_HELPERS_SORT = 1

; Shellsort an array. The unit used is byte.
; aa aa aa aa - Address
; 00 00 ss ss - Size
Shellsort:
	SetupFramePointer
	move.l	a2, -(sp)

	cmpi.w	#2,	10(fp)
	blo		Shellsort_End	; nothing to do for items less than 2

	; while size != 0
	; 	divide size by 2
	;	for i = 0 to size - 1
	;		cursor = address + i
	;		loop
	;			if cursor + size < end
	;				cursor += size
	;			else
	;				break
	;		loop
	;			if cursor - size >= address
	;				left = cursor - size
	;				if *left > *cursor
	;					swap *left and *cursor
	;				cursor = left
	;			else
	;				break

	move.l	4(fp), a1
	add.l	8(fp), a1				; a1 = end = address + size

Shellsort_While_SizeNot0:
	move.w	10(fp), d0
	lsr.w	#1, d0
	tst.w	d0
	beq		Shellsort_End			; while size != 0
	move.w	d0, 10(fp)				; size / 2

	move.l	#0, d1					; d1 = i = 0
Shellsort_For_0ToSizeMinus1:
	move.l	4(fp), a0
	add.l	d1, a0					; a0 = cursor = address + i

Shellsort_For_Loop1:
	move.l	8(fp), d0
	add.l	a0, d0
	cmp.l	a1, d0
	bhs		Shellsort_For_Loop2		; if cursor + size >= end, break

	move.l	d0, a0					; cursor += size
	bra		Shellsort_For_Loop1

Shellsort_For_Loop2:
	move.l	a0, d0
	sub.l	8(fp), d0
	cmp.l	4(fp), d0
	blo		Shellsort_For_Next		; if cursor - size < address, break

	move.l	d0, a2					; a2 = left = cursor - size

	move.b	(a2), d0
	cmp.b	(a0), d0
	bls		Shellsort_For_Loop2_Next ; if *left <= *cursor, skip next step

	move.b	(a2), d0				; move *left to d0
	move.b	(a0), (a2)				; overwrite *left with *cursor
	move.b	d0, (a0)				; overwrite *cursor with d0, original *left

Shellsort_For_Loop2_Next:
	move.l	a2, a0					; cursor = left
	bra		Shellsort_For_Loop2

Shellsort_For_Next:
	add.l	#1, d1					; i++
	move.l	8(fp), d0
	subi.l	#1, d0					; size - 1
	cmp.l 	d0, d1
	bls		Shellsort_For_0ToSizeMinus1 ; next if i is <= size - 1

	bra		Shellsort_While_SizeNot0 ; Next iteration of the while loop

Shellsort_End:
	move.l	(sp)+, a2
	RestoreFramePointer
	rts

	endif