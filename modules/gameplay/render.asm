	ifnd H_GAMEPLAY_RENDER
H_GAMEPLAY_RENDER = 1

	include 'modules/framebuffer/framebuffer.asm'

RenderThread:

	jsr LoadTitlescreen

RenderThread_ControllerInput:
	move.b	(JOYPAD_STATE_1), d0
	andi.b	#JOYPAD_START, d0
	beq.s 	RenderThread_ControllerInput

RenderThread_VdpSwitch:
	VdpErasePlane #VDP_TITLESCREEN_PLANE_A

	jsr InitFramebuffer

	; Plot a tiny little white pixel 0,0
	FramebufferPutPixel #$0F002525
	FramebufferPutPixel #$0F002626
	FramebufferPutPixel #$0F002727
	FramebufferPutPixel #$0D002828
	jsr SwapFramebuffer

RenderThread_EternalLoop:
	jmp RenderThread_EternalLoop

	endif