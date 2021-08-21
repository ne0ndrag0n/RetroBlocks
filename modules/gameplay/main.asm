	ifnd H_GAMEPLAY_MAIN
H_GAMEPLAY_MAIN=1

MainLoop:
	jsr Render
	bra.s MainLoop

	endif