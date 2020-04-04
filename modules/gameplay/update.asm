	ifnd H_GAMEPLAY_UPDATE
H_GAMEPLAY_UPDATE = 1

UpdateThread:
	move.l	($FF00B4), d0
	addi.l  #1, d0
	move.l  d0, ($FF00B4)
	jmp UpdateThread

	endif