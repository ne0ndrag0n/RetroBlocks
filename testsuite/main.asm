; Testsuite contains several -D options that will compile the ROM after init.asm with a new program

	include 'modules/helpers/debug.asm'
	include 'modules/worldgen/mod.asm'
	include 'modules/gameplay/mod.asm'
TESTSUITE_FUNCTION = TestDmaQueue

TestIsoblender:
	; Set up isoblender test
	VdpClearVram		#$F3FF / 2, #$0C00
	VdpSendCommandList 	#VdpGameplayState, #( (VdpGameplayState_End - VdpGameplayState)/2 ) - 1

	VdpLoadPaletteDma	#VDP_PAL_0, #VGAPalette
	VdpLoadPaletteDma	#VDP_PAL_1, #TestIsoblender_Data_PartialPal

	VdpLoadPatternDma	#TS_FONT_LOCATION, #96, #Font

	VdpDrawText #$0000, #VDP_GAMEPLAY_PLANE_A, #String_LongTest

TestIsoblender_Begin:
	IsoblenderRenderBoard	#0000, #0000, #WorldgenTest

TestIsoblender_Loop:
	bra.s TestIsoblender_Loop

TestDmaQueue:
	VdpGetControlWord #$0000, #( VDP_VRAM_WRITE | VDP_DMA_ADDRESS )
	VdpDmaQueueEnqueue #32, #Font, d0	; load two characters from font into top of VRAM

	VdpGetControlWord #$0040, #( VDP_VRAM_WRITE | VDP_DMA_ADDRESS )
	DebugPrintLabelHere
	VdpDmaQueueEnqueue #32, #Font + 64, d0	; load two characters from font into top of VRAM
	jsr DmaQueueExecute

TestDmaQueue_Loop:
	bra.s TestDmaQueue_Loop