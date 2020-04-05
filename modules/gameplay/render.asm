	ifnd H_GAMEPLAY_RENDER
H_GAMEPLAY_RENDER = 1

RenderThread:

	jsr LoadTitlescreen

RenderThread_ControllerInput:
	move.b	(JOYPAD_STATE_1), d0
	andi.b	#JOYPAD_START, d0
	beq.s 	RenderThread_ControllerInput

RenderThread_VdpSwitch:
	VdpClearVram		#$F3FF / 2, #$0C00
	VdpSendCommandList 	#VdpGameplayState, #( (VdpGameplayState_End - VdpGameplayState)/2 ) - 1

	VdpDrawText #$0101, #VDP_TITLESCREEN_PLANE_A, #String_Overworld

RenderThread_EternalLoop:
	jmp RenderThread_EternalLoop

	endif