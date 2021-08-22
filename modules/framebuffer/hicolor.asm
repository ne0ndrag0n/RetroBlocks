	ifnd H_HICOLOR
H_HICOLOR=1

HICOLOR_REMAINING_COLORS = $FF000E
HICOLOR_NEXT_HBLANK_WORD = $FF00A4
HICOLOR_PALETTES         = $FF00A8

HICOLOR_SECOND_PAL_PAIR  = $80
HICOLOR_DUMMY_WRITE      = $94009400

HICOLOR_PALETTES_SIZE    = 896

; The Hicolor module allows multiplexing palettes across the display to squeeze a few more colours out of the MD.
; Every 32 lines on screen, the MD will switch to a different palette pair usable for that region of the display.

; Across 224 lines, you can use up to 28 different palettes, giving you up to 444 colours on screen with some restrictions:
; * Each 16-line region on screen has its own Palette Pair, forming a Palette Pair Region.
; * Within each Palette Pair Region, an 8x8 region of the screen may select one of two 16-colour palettes.
; * The 0th colour in each palette remains the "transparent" colour and cannot be set.

; Memory regions needed:
; HICOLOR_REMAINING_COLORS - 1 byte, the number of palette entries remaining to write in this Palette Pair.
;
;							 When this reaches 0, the most significant bit signifies whether to begin writing
;                            PAL0/PAL1 (0), or PAL2/PAL3 (1) after the counter is reset to 16.
;
; HICOLOR_NEXT_HBLANK_WORD - 4 bytes, this control word is sent every HBlank.
;
; HICOLOR_PALETTES - 896 bytes, contains the Palette Pairs for each Palette Pair Region.
;                    28 vertical cells * 32 bytes per palette

; -----

; * Set HICOLOR_REMAINING_COLORS to 16 for first palette pair.
; * Set HICOLOR_NEXT_HBLANK_WORD to the dummy write.
; * Blank all HICOLOR_PALETTES.
InitHicolor:
	move.b	#16, HICOLOR_REMAINING_COLORS
	move.l	#HICOLOR_DUMMY_WRITE, HICOLOR_NEXT_HBLANK_WORD

	move.w	#( ( HICOLOR_PALETTES_SIZE / 4 ) - 1 ), d0		; (896/4) - 1 = 223
	move.l	#HICOLOR_PALETTES, a0
InitHicolor_ClearPalettes:
	move.l	#0, (a0)+
	dbra	d0, InitHicolor_ClearPalettes

	rts

; Set up a test ramp for palettes. Lines 0-7 use PAL0, assigned to ChromaRamp, and lines 8-15 use PAL1, assigned to ChromaRampRed.
; To test palette loading in runtime, 16-23 will use PAL2 assigned to VGAPalette, while 24-31 will use PAL3 assigned to Bread.
; The remaining lines will be set to ChromaRamp/PAL0.
SetupHicolorTestValues:
	move.l	a2, -(sp)
	move.l 	d2, -(sp)
	move.l	d3, -(sp)
	move.l	d4, -(sp)

	move.l	#HICOLOR_PALETTES, a2
	move.w	#27, d2					; There are 28 palettes to copy

SetupHicolorTestValues_WriteChromaRamps:
	MemCopy	#ChromaRamp, a2, #32
	add.l	#32, a2
	dbra	d2, SetupHicolorTestValues_WriteChromaRamps

	; Write ChromaRampRed palette in the second hicolor palette
	MemCopy	#ChromaRampRed, #(HICOLOR_PALETTES + 32), #32

	; Third hicolor palette should use VGAPalette
	MemCopy #VGAPalette, #(HICOLOR_PALETTES + 64), #32

	; Finally, fourth hicolor palette should be Bread
	MemCopy #Bread, #(HICOLOR_PALETTES + 96), #32

	; Write nametables to set PAL2 every $100 bytes
	move.l	#$0000E100, d2

SetupHicolorTestValues_WriteOddRow:
	move.w	#127, d4

SetupHicolorTestValues_WritePal2:
	VdpGetControlWord d2, #VDP_VRAM_READ
	DisableInterrupts
	move.l	d0, VDP_CONTROL
	move.w	VDP_DATA, d3
	EnableInterrupts

	ori.w	#$4000, d3
	andi.w	#(~$2000), d3		; Set "10" as palette

	VdpGetControlWord d2, #VDP_VRAM_WRITE
	DisableInterrupts
	move.l	d0, VDP_CONTROL
	move.w	d3, VDP_DATA
	EnableInterrupts

	addi.w	#2, d2
	dbra	d4, SetupHicolorTestValues_WritePal2

	addi.w	#$0100, d2
	cmpi.w	#$EF00, d2
	bls.s	SetupHicolorTestValues_WriteOddRow

	move.l	(sp)+, d4
	move.l 	(sp)+, d3
	move.l	(sp)+, d2
	move.l	(sp)+, a2
	rts

StartHicolor:
	rts

StopHicolor:
	rts

HicolorOnNextFrame:
	rts

HBlank:
	rte

	endif