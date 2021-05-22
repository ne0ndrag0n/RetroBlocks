	ifnd H_FRAMEBUFFER
H_FRAMEBUFFER = 1

InitFramebuffer:
	move.l  #FRAMEBUFFER, a0
	move.w	#FRAMEBUFFER_SIZE, d0

	lsr.w	#2, d0					; Divide by 4, by shifting right 2.
									; Because when we clear the framebuffer, we write 0 as a long.

	subi.w	#1, d0					; dbra instruction will run an extra iteration for 0

InitFramebuffer_Clear:
	move.l	#0, (a0)+					; Clear framebuffer
	dbra.w	d0, InitFramebuffer_Clear

	rts

PutPixel:
	rts

	endif