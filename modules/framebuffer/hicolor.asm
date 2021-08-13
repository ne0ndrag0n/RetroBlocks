	ifnd H_HICOLOR
H_HICOLOR = 1

HICOLOR_PALETTES = $FF0100
HICOLOR_PALETTES_WORDS = 16*224
HICOLOR_PALETTE_CELLS = $FF1D00
HICOLOR_PALETTE_CELLS_WORDS = 40*28
HICOLOR_NEXT_LINE = $FF25C0
HICOLOR_SYSTEM_STATUS_ENABLE = $02

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
	move.l 	#0, HICOLOR_NEXT_LINE		; Signal to vblank handler that hblank must be enabled
	rts

; Disable HiColor mode. For the next frame, PAL0 will remain at the palette defined in line 224.
StopHiColor:
	andi.b	#(~HICOLOR_SYSTEM_STATUS_ENABLE), SYSTEM_STATUS
	move.w	#( $8000 | VDP_REG01_DEFAULTS ), VDP_CONTROL			; Disable hblank
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

	; *Now*, set up the DMA for the first hblank, which will affect line 1.
	; Next hblank will catch line 1, and do the rest.
	move.l	#( $97009600 | ( ( ( HICOLOR_PALETTES + 32 ) >> 1 ) & $00FF0000 ) | ( ( ( ( HICOLOR_PALETTES + 32 ) >> 1 ) & $0000FF00 ) >> 8 ) ), VDP_CONTROL
	move.w	#( $9500 | ( ( ( HICOLOR_PALETTES + 32 ) >> 1 ) & $000000FF ) ), VDP_CONTROL

	tst.l	HICOLOR_NEXT_LINE
	bne.s	HiColorFrameSync_SetupNextLine		; Determine if we need to enable hblank (first enabling)

	move.w	#( $8000 | VDP_HBLANK_ENABLED ), VDP_CONTROL		; Enable hblank
																; * Assuming we never stop the hvcounter because this will start it back up!
																; * Next statement will set up HICOLOR_NEXT_LINE, which would've been done anyway

	move.w	#$8A00, VDP_CONTROL		; Set hblank interrupt counter to go for every line. This should already be done elsewhere,
									; but is put here to establish a consistent state.

HiColorFrameSync_SetupNextLine:
	; HICOLOR_NEXT_LINE is line 1 (NOT line 0)
	move.l	#(HICOLOR_PALETTES + 32), HICOLOR_NEXT_LINE

HiColorFrameSync_End:
	rts

; Method linked in vectors.asm. The only use of hblank so far will be for the HiColor module.
; Color swap for the next line has to happen QUICK! See comments below.
HBlank:
	; BEFORE YOU EVER GET HERE:
	; * VDP Registers 19 and 20 set to 16 and 0 respectively
	; * VDP Registers 21, 22, and 23 set to the appropriate segment of HICOLOR_PALETTES

	; DON'T TOUCH DMA REGISTERS OUTSIDE OF VBLANK OR HBLANK OR YOU DIE BECAUSE I KILL YOU
	; Existing methods that do so are ~deprecated~ !!

	; Can't have this fucking shit up
	DisableInterrupts

	; Disable the screen by writing default video mode to register 01, minus screen enabled
	move.w	#( $8100 | ( VDP_DEFAULT_VIDEO_MODE & ~VDP_SCREEN_ENABLED ) ), VDP_CONTROL

	; Shoot off DMA to CRAM for this line.
	move.l	#( VDP_CRAM_WRITE | VDP_DMA_ADDRESS ), VDP_CONTROL

	; Tough stuff's over. Turn the screen back on.
	move.w	#( $8100 | VDP_DEFAULT_VIDEO_MODE ), VDP_CONTROL

	; Do we even need to do anything else?
	cmpi.l 	#(HICOLOR_PALETTES + ( 32*224 ) ), HICOLOR_NEXT_LINE		; If the next HiColor line was marked as past HICOLOR_PALETTES...
	bhs.s	HBlank_End													; Skip anything else, counter will be reset at end of next vblank.

	; CRAM already written. Now you can take your time to set up the next HBLANK.
	move.l	#$94009310, VDP_CONTROL				; Set DMA to 16 word palette - just in case something fucked this up

	move.l	d0, -(sp)							; Need to preserve existing d0
	move.l	#$97009600, -(sp)					; Allocate another long for register write (upper and middle bytes)

	move.l	HICOLOR_NEXT_LINE, d0
	lsr.l	#1, d0
	move.l	d0, HICOLOR_NEXT_LINE				; Need to shift right by 1 as we write it to DMA regs

	andi.l	#$00FF0000, d0
	or.l	d0, (sp)							; Take upper byte only and write it to register long

	move.l	HICOLOR_NEXT_LINE, d0
	andi.l	#$0000FF00, d0 						; Take middle byte only
	lsr.l	#8, d0
	or.l	d0, (sp)							; And write it to register long

	move.l	(sp), VDP_CONTROL					; Write generated control long
	move.w	#$9500, (sp)						; Then write new control word

	move.l	HICOLOR_NEXT_LINE, d0
	andi.l	#$000000FF, d0						; Take lower byte only
	or.w	d0, (sp)							; And write it to register word

	move.w	(sp), VDP_CONTROL					; Send last VDP control word

HBlank_End:
	; Restore interrupts and return
	EnableInterrupts
	rte

	endif