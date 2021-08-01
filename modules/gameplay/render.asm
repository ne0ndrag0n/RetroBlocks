	ifnd H_GAMEPLAY_RENDER
H_GAMEPLAY_RENDER = 1

	include 'modules/framebuffer/framebuffer.asm'

RenderThread:
	HeapInit
	jsr LoadTitlescreen

RenderThread_ControllerInput:
	move.b	(JOYPAD_STATE_1), d0
	andi.b	#JOYPAD_START, d0
	beq.s 	RenderThread_ControllerInput

RenderThread_VdpSwitch:
	VdpErasePlane #VDP_TITLESCREEN_PLANE_A

	jsr InitFramebuffer

RenderThread_EternalLoop:
	jmp RenderThread_EternalLoop

	endif