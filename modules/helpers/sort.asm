	ifnd H_HELPERS_SORT
H_HELPERS_SORT = 1


	macro SortCocktailShaker
		move.w	\2, -(sp)
		move.l	\1, -(sp)
		jsr CocktailShaker
		PopStack 6
	endm

	macro Sort
		move.l	\1, -(sp)
		move.l	#0, -(sp)
		move.w	\2,	2(sp)
		jsr Quicksort
		PopStack 8
	endm

; Sort using cocktail shaker method. This is not recommended for
; large list sizes.
; aa aa aa aa - Address of list
; 00 nn - Number of items
CocktailShaker:

	move.w	#0, -(sp)		; (sp) Counter
							; 1(sp) Whether or not we swapped while passing through

	subi.b	#1, 2+9(sp)		; Subtract 1 from counter because we check things in pairs

CocktailShaker_ForwardLoop_Start:
	move.l	2+4(sp), a0		; a0 = address of the list

CocktailShaker_ForwardLoop:
	move.b	(sp), d0
	cmp.b	2+9(sp), d0
	beq.s	CocktailShaker_BackLoop			; Jump to the back loop

	move.b	(a0)+, d0						; Check if current value is greater than the next value
	cmp.b	(a0), d0
	bls.s	CocktailShaker_ForwardLoop

	; The value before the next, is greater than the next
	; They must be swapped

	move.b	#1, 2+1(sp)						; Mark that a swap occurred

	move.b	(a0), -(a0)						; Move value in a0 to one byte before
	add.l	#1, a0							; Work around vasm bug
	move.b	d0, (a0)						; Move value that was before, after

	addi.b	#1, (sp)						; Increment counter by 1
	bra.s	CocktailShaker_ForwardLoop		; Next item

CocktailShaker_BackLoop:
	tst.b	(sp)
	beq.s	CocktailShaker_CheckSwapped		; Don't actually encounter the last item

	move.b	(a0), d0
	sub.l	#1, a0							; Get value at counter

	cmp.b	(a0), d0
	bhs.s	CocktailShaker_BackLoop			; Check d0 against next value (going backwards), if it's greater do nothing

	; The value before the next (going backwards), is lesser than the next
	; They must be swapped

	move.b	#1, 2+1(sp)						; Mark that a swap occurred

	move.b	(a0), d1
	add.l	#1, a0
	move.b	d1, (a0)						; Higher value gets moved up

	sub.l	#1, a0
	move.b	d0, (a0)						; Lower value gets moved down

	subi.b	#1, (sp)						; Decrement counter
	bra.s	CocktailShaker_BackLoop			; Next item

CocktailShaker_CheckSwapped:

	tst.b	1(sp)							; If we did a swap at some point, we need to keep going
	beq.s	CocktailShaker_ForwardLoop		; Perform the "cocktail shaker" action by going back from the front

	; Once we get here, it's all done

	PopStack 2
	rts

; Ref: https://rosettacode.org/wiki/Sorting_algorithms/Quicksort#C
; 00 00 ss ss - Array size
; aa aa aa aa - Array address (bytes)
Quicksort:
	cmpi.w	#2, 6(sp)
	blo		Quicksort_End

	move.l	8(sp), a0		; a0 = array

	move.l	a0, a1
	move.l	4(sp), d0
	lsr.w	#1, d0
	add.l	d0, a1			; a1 is pivot = array[ size / 2 ]

	move.l	d2, -(sp)
	move.l	d3, -(sp)		; Save existing regs

	move.l	#0, d2			; i = 0
	move.l	6(sp), d3
	subi.w	#1, d3			; j = size - 1

Quicksort_For:
Quicksort_WhileI:
	move.b	(a0, d2), d0
	cmp.b	(a1), d0
	bhs		Quicksort_WhileJ	; while array[ i ] < pivot, i++
	addi.w	#1, d2
	bra		Quicksort_WhileI

Quicksort_WhileJ:
	move.b	(a0, d3), d0
	cmp.b	(a1), d0
	bls		Quicksort_BreakCheck ; while array[ j ] > pivot, j--
	subi.w	#1, d3
	bra		Quicksort_WhileJ

Quicksort_BreakCheck:
	cmp.w	d3, d2
	bhs		Quicksort_Recurse	; if i >= j then break

	move.b	d4, -(sp)
	move.b	(a0, d2), d4		; temp = array[ i ]
	move.b	(a0, d3), (a0, d2)	; array[ i ] = array[ j ]
	move.b	d4, (a0, d3)		; array[ j ] = temp
	move.b	(sp)+, d4

	addi.w	#1, d2
	subi.w	#1, d3
	bra		Quicksort_For

Quicksort_Recurse:
	move.l	a0, -(sp)
	move.l	d2, -(sp)
	move.l	d3, -(sp)
		move.l	a0, -(sp)
		move.l	d2, -(sp)
		jsr Quicksort				; recursive call using arguments array, i
		PopStack 8
	move.l	(sp)+, d3
	move.l	(sp)+, d2
	move.l	(sp)+, a0

	move.l	a0, -(sp)
	move.l	d2, -(sp)
	move.l	d3, -(sp)
		add.l	d2, a0				; array + i
		move.l	4(sp), d3			; stomp d3 for len - i
		sub.l	d2, d3				; d3 will get put back anyway...
		move.l	a0, -(sp)
		move.l	d3, -(sp)
		jsr Quicksort
		PopStack 8
	move.l	(sp)+, d3
	move.l	(sp)+, d2
	move.l	(sp)+, a0

	move.l	(sp)+, d3
	move.l	(sp)+, d2

Quicksort_End:
	rts

	endif