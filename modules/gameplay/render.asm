	ifnd H_GAMEPLAY_RENDER
H_GAMEPLAY_RENDER = 1

	include 'modules/framebuffer/mod.asm'

Render:
	HeapInit
	jsr LoadTitlescreen

Render_ControllerInput:
	move.b	(JOYPAD_STATE_1), d0
	andi.b	#JOYPAD_START, d0
	beq.s 	Render_ControllerInput

Render_VdpSwitch:
	VdpErasePlane #VDP_TITLESCREEN_PLANE_A

	jsr InitFramebuffer
	jsr Test_FramebufferGenerateRamp

Render_EternalLoop:
	bra.s Render_EternalLoop

; Fill framebuffer with a chroma ramp and swap palette to chroma ramp
; This will be used to test Hicolor mode
Test_FramebufferGenerateRamp:
	VdpLoadPaletteDma #VDP_PAL_0, #ChromaRamp

	move.l	#FRAMEBUFFER, a0
	move.w	#FRAMEBUFFER_SIZE, d0
	lsr.w	#2, d0
	subi.w	#1, d0

Test_FramebufferGenerateRamp_Loop:
	move.l	#$02468ACE, (a0)+
	dbra	d0, Test_FramebufferGenerateRamp_Loop

	jsr		SwapFramebuffer
	rts

	endif