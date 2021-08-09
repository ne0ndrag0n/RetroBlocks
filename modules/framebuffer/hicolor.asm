	ifnd H_HICOLOR
H_HICOLOR = 1

HICOLOR_PALETTES = $FF0100
HICOLOR_PALETTES_WORDS = 16*224
HICOLOR_PALETTE_CELLS = $FF1D00
HICOLOR_PALETTE_CELLS_WORDS = 40*28
HICOLOR_NEXT_LINE = $FF25C0

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

; When called, set up DMA for next hblank (but do not trigger dma), and enable hblank.
StartHiColor:
	; 16 word DMA
	TakeVdpControlLock
	move.l	#$94009310, VDP_CONTROL

	; The first DMA will occur on vertical line #1
	; which is located at HICOLOR_PALETTES + 16
	; Hardcoded that's $7F8090 written to regs 23, 22, and 21 ($97, $96, $95)
	move.l	#$977F9680, VDP_CONTROL
	move.w	#$9590, VDP_CONTROL
	ReleaseVdpControlLock

	; When this routine is called, we have no earthly idea where we are on the screen.
	; We need to sync up with the beam in the top left corner for mode H40/V28.
	; That HVCounter value will be #$001A, see https://gendev.spritesmind.net/forum/viewtopic.php?t=3058#p35660
StartHiColor_Sync:
	cmpi.w	#$001A, VDP_HVCOUNTER
	bne.s	StartHiColor_Sync

	; TODO: Enable hblank right here and kick it all off! First HiColor line will be DMA'd as line 01.
	rts

; Called at the end of the vblank routine. Set the HiColor DMA to fire for line 0.
HiColorFrameSync:
	; Buggy until we make all DMA go through either vblank or hblank
	; Need to write blocking dma queue functions
	;move.l	#$94009310, VDP_CONTROL
	;move.l	#$977F9680, VDP_CONTROL
	;move.w	#$9580, VDP_CONTROL
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