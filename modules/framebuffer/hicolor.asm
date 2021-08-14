	ifnd H_HICOLOR
H_HICOLOR = 1

HICOLOR_PALETTES = $FF0100
HICOLOR_PALETTES_WORDS = 16*224
HICOLOR_PALETTE_CELLS = $FF1D00
HICOLOR_PALETTE_CELLS_WORDS = 40*28
HICOLOR_NEXT_LINE = $FF25C0

HICOLOR_SYSTEM_STATUS_ENABLE = $02
HICOLOR_SYSTEM_STATUS_HBLANK_ENABLE = $04

; Get the address of the first byte of a given HiColor palette.
	macro GetHiColorPaletteAddress
		move.l	\1, d0						; Number of times we need to multiply by 32 bytes
		lsl.l	#5, d0						; Multiply \1 by 32 (x << 5 is x * 32)
		addi.l	#HICOLOR_PALETTES, d0		; Add HICOLOR_PALETTES to get address
	endm

; Initialise Hicolor mode:
; * Clear palettes 0-223 (HICOLOR_PALETTES) (7168 bytes)
; * Set cell palette tables to zero (HICOLOR_PALETTE_CELLS) (2240 bytes)
InitHiColor:
	move.l #HICOLOR_PALETTES, a0
	move.w #HICOLOR_PALETTES_WORDS, d1
	subi.w #1, d1

InitHiColor_ClearPalettes:
	move.w #0, (a0)+
	dbra   d1, InitHiColor_ClearPalettes

	; ---

	move.l #HICOLOR_PALETTE_CELLS, a0
	move.w #HICOLOR_PALETTE_CELLS_WORDS, d1
	subi.w #1, d1

InitHiColor_ClearCells:
	move.w #0, (a0)+
	dbra   d1, InitHiColor_ClearCells
	rts

; Enable HiColor mode by triggering the HiColor bit in SYSTEM_STATUS. HiColor will enable next frame.
StartHiColor:
	ori.b	#HICOLOR_SYSTEM_STATUS_ENABLE, SYSTEM_STATUS
	ori.b	#HICOLOR_SYSTEM_STATUS_HBLANK_ENABLE, SYSTEM_STATUS		; Signal to vblank handler that hblank must be enabled
	rts

; Disable HiColor mode. For the next frame, PAL0 will remain at the palette defined in line 224.
StopHiColor:
	andi.b	#(~HICOLOR_SYSTEM_STATUS_ENABLE), SYSTEM_STATUS
	move.w	#( $8000 | VDP_REG00_DEFAULTS ), VDP_CONTROL			; Disable hblank
	rts

; Set up HiColor mode for this frame upon end of vblank.
HiColorFrameSync:
	btst	#1, SYSTEM_STATUS
	beq.s	HiColorFrameSync_End				; Don't touch anything here unless HiColor Sync flag is 1

HiColorFrameSync_RegisterSetup:
	; When we call this, we're still in vblank, probably right there near the end. We will need to send the HiColor state for the first horizontal line.
	move.l	#$94009310, VDP_CONTROL
	move.l	#( $97009600 | ( ( HICOLOR_PALETTES >> 1 ) & $00FF0000 ) | ( ( ( HICOLOR_PALETTES >> 1 ) & $0000FF00 ) >> 8 ) ), VDP_CONTROL
	move.w	#( $9500 | ( ( HICOLOR_PALETTES >> 1 ) & $000000FF ) ), VDP_CONTROL

	; DMA to PAL0 before first line is drawn
	; No need to disable the screen here! When line 0 is drawn it will work properly
	move.l	#( VDP_CRAM_WRITE | VDP_DMA_ADDRESS ), VDP_CONTROL

	; After this operation the DMA source regs should autoincrement 16 words, but the counter will run out.
	; So set the counter up for the next line. TODO: We *might* be able to get away with just the lower word?
	move.l	#$94009310, VDP_CONTROL

	btst	#2, SYSTEM_STATUS
	beq.s	HiColorFrameSync_End								; Determine if hblank needs to be enabled

	move.w	#( $8000 | VDP_REG00_DEFAULTS | VDP_HBLANK_ENABLED ), VDP_CONTROL		; Enable hblank
																					; * Assuming we never stop the hvcounter because this will start it back up!

	move.w	#$8A00, VDP_CONTROL									; Set hblank interrupt counter to go for every line. This should already be done elsewhere,
																; but is put here to establish a consistent state.

	andi.b	#(~HICOLOR_SYSTEM_STATUS_HBLANK_ENABLE), SYSTEM_STATUS		; hblank doesn't need to be enabled next vblank

HiColorFrameSync_End:
	rts

; Method linked in vectors.asm. The only use of hblank so far will be for the HiColor module.
; Color swap for the next line has to happen QUICK! See comments below.
HBlank:
	; BEFORE YOU EVER GET HERE:
	; * VDP Registers 19 and 20 set to 16 and 0 respectively
	; * VDP Registers 21, 22, and 23 set to the appropriate segment of HICOLOR_PALETTES

	; Can't have this fucking shit up
	DisableInterrupts

	; Disable the screen by writing default video mode to register 01, minus screen enabled
	move.w	#( $8100 | ( VDP_DEFAULT_VIDEO_MODE & ~VDP_SCREEN_ENABLED ) ), VDP_CONTROL

	; Shoot off DMA to CRAM for this line.
	move.l	#( VDP_CRAM_WRITE | VDP_DMA_ADDRESS ), VDP_CONTROL

	; Tough stuff's over. Turn the screen back on.
	move.w	#( $8100 | VDP_DEFAULT_VIDEO_MODE ), VDP_CONTROL

	; Length must be reset to 16 words for the next hblank
	; If you touch this anywhere else in the code, you die
	move.l	#$94009310, VDP_CONTROL

HBlank_End:
	; Restore interrupts and return
	EnableInterrupts
	rte

	endif