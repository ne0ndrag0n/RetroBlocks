	ifnd H_HICOLOR
H_HICOLOR=1

HICOLOR_REMAINING_COLORS = $FF000E
HICOLOR_NEXT_HBLANK_WORD = $FF00A4
HICOLOR_PALETTES         = $FF00A8

HICOLOR_ENABLED          = $02
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

; Start the Hicolor module. The first effects will be seen in HicolorOnNextFrame.
StartHicolor:
	ori.b	#HICOLOR_ENABLED, SYSTEM_STATUS
	move.w	#$8A00, VDP_CONTROL										; Set the hblank counter to go for every line
	rts

; Stop Hicolor mode.
StopHicolor:
	andi.b	#(~HICOLOR_ENABLED), SYSTEM_STATUS
	move.w	#( $8000 | VDP_REG00_DEFAULTS ), VDP_CONTROL			; Disable hblank
	rts

; Detect if Hicolor is enabled, and if so, set up the next frame and enable hblank. This item needs to be at the end of vblank.
HicolorOnNextFrame:
	btst	#1, SYSTEM_STATUS
	beq.s	HicolorOnNextFrame_End		; Do nothing if zero

	; Disable hblank while we're in here.
	move.w	#( $8000 | VDP_REG00_DEFAULTS ), VDP_CONTROL

	; Setup first DMA: DMA origin HICOLOR_PALETTES
	move.l	#( $97009600 | ( ( HICOLOR_PALETTES >> 1 ) & $00FF0000 ) | ( ( ( HICOLOR_PALETTES >> 1 ) & $0000FF00 ) >> 8 ) ), VDP_CONTROL
	move.w	#( $9500 | ( ( HICOLOR_PALETTES >> 1 ) & $000000FF ) ), VDP_CONTROL

	; Send the first palette pair right here in vblank, to prepare for the first 16-line region on screen.
	move.l	#$94009320, VDP_CONTROL
	move.l	#( VDP_CRAM_WRITE | VDP_DMA_ADDRESS ), VDP_CONTROL

	; Autoincrement will bring the source counter up properly at this point.
	; Reset the vdp counter for the first two colours of the first PAL2/PAL3 palette pair.
	move.w	#$9302, VDP_CONTROL

	; Stage HICOLOR_NEXT_HBLANK_WORD to CRAM Write, DMA, $0044 for first hblank.
	move.l	#( VDP_CRAM_WRITE | VDP_DMA_ADDRESS | ( $0044 << 16 ) ), HICOLOR_NEXT_HBLANK_WORD

	; Burn remaining time in vblank and sync to line 0
	; If we're already late, there's too much going on in vblank...
HicolorOnNextFrame_SyncLine0:
	btst	#3, VDP_CONTROL + 1
	bne.s	HicolorOnNextFrame_SyncLine0

	; Send the first two colours of the first PAL2/PAL3 palette pair.
	move.l	#( VDP_CRAM_WRITE | VDP_DMA_ADDRESS | ( $0040 << 16 ) ), VDP_CONTROL

	; Start hblank. Warning: unfrezes the hvcounter if you had it frozen.
	move.w	#( $8000 | VDP_REG00_DEFAULTS | VDP_HBLANK_ENABLED ), VDP_CONTROL
	move.w	#$9302, VDP_CONTROL

HicolorOnNextFrame_End:
	rts

; This is the global HBlank as set in the vector table. It will only ever be used for Hicolor mode.
; Every hblank you get two slots to send two colours. This will continuously send the colours, in
; preparation for the subsequent 16-line Palette Pair Regions.
HBlank:
	; Sending a color has to happen NOW!
	move.l	#$94009400, VDP_CONTROL
	move.l	#$94009400, VDP_CONTROL

	move.l	HICOLOR_NEXT_HBLANK_WORD, VDP_CONTROL
	move.w	#$9302, VDP_CONTROL

	; After that we do everything necessary for the next hblank.
	cmpi.w	#$C07C, HICOLOR_NEXT_HBLANK_WORD	; Did we just write the last colour of PAL3 (CRAM write, $7C)?
	beq.s	HBlank_ResetPal						; Something else needs to be done here

	addi.w	#4, HICOLOR_NEXT_HBLANK_WORD		; Increment by 4 bytes. The upper bits shouldn't be affected.
	bra.s	HBlank_End

HBlank_ResetPal:
	move.w	#$C000, HICOLOR_NEXT_HBLANK_WORD	; If we got here, we're looping back around to PAL0.

HBlank_End:
	rte

	endif