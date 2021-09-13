	ifnd H_GAMEPLAY_MAIN
H_GAMEPLAY_MAIN=1

MainLoop:
	MemCopy	#SortTest, #$FF00A4, #10
	Sort	#$FF00A4, #10

	jsr Render

EndLoop:
	bra.s EndLoop

	endif