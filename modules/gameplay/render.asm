	ifnd H_GAMEPLAY_RENDER
H_GAMEPLAY_RENDER = 1

RenderThread:

	jsr LoadTitlescreen

RenderThread_EternalLoop:
	move.l	($FF00B0), d0
	addi.l  #1, d0
	move.l  d0, ($FF00B0)
	jmp RenderThread_EternalLoop

	endif