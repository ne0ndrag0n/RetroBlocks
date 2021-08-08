	ifnd H_HICOLOR
H_HICOLOR = 1

HICOLOR_PALETTES = $FF0100
HICOLOR_PALETTE_CELLS = $FF1D00
HICOLOR_NEXT_LINE = $FF25C0

; Initialise Hicolor mode:
; * Clear palettes 0-223 (HICOLOR_PALETTES) (7168 bytes)
; * Set cell palette tables to zero (HICOLOR_PALETTE_CELLS) (2240 bytes)
; * Set up hblank for the first interrupt by syncing to 1+current vertical line - do this quick and at the end!
InitHiColor:
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

	; TODO: CRAM already written. Now you can take some time to set up the next HBLANK.

	; Restore interrupts and return
	EnableInterrupts
	rte

	endif