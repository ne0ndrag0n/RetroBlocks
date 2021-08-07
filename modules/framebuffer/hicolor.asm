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
; Color swap for the next line has to happen QUICK! ~32 cycles. Do not waste time; disable the screen + interrupts, and send
; 32 bytes unrolled. After that you can take more time to set up the next line's palette.
HBlank:
	rte

	endif