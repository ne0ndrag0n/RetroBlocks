	ifnd H_GAMEPLAY_RENDER
H_GAMEPLAY_RENDER = 1

	include 'modules/framebuffer/mod.asm'

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

	; Here we do some things to test HiColor
	jsr Test_FramebufferGenerateRamp
	jsr InitHiColor
	jsr Test_FillHiColorPalettes

RenderThread_EternalLoop:
	jmp RenderThread_EternalLoop

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

; Generate example HiColor palette range for lines 0-111 and 213-223
; Load HiColor palettes for lines 112-212 for shits and giggles
Test_FillHiColorPalettes:
	move.l	d2, -(sp)

	move.w	#223, d2			; This will end up filling it from 223 to 0
Test_FillHiColorPalettes_Loop:
	GetHiColorPaletteAddress d2
	MemCopy #ChromaRamp, d0, #32
	dbra	d2, Test_FillHiColorPalettes_Loop

	move.w	#112, d2
Test_FillHiColorPalettes_RedLoop:
	GetHiColorPaletteAddress d2
	MemCopy	#ChromaRampRed, d0, #32
	addi.w	#1, d2
	cmpi.w	#213, d2
	blo.s	Test_FillHiColorPalettes_RedLoop

	move.l	(sp)+, d2
	rts

	endif