	ifnd H_HELPERS_SORT
H_HELPERS_SORT = 1


	macro SortCocktailShaker
		move.w	\2, -(sp)
		move.l	\1, -(sp)
		jsr CocktailShaker
		PopStack 6
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

	endif