	ifnd H_FRAMEBUFFER
H_FRAMEBUFFER = 1

; Clear framebuffer - Mark FRAMEBUFFER_SIZE region 0
ClearFramebuffer:
	move.l  #FRAMEBUFFER, a0
	move.w	#FRAMEBUFFER_SIZE, d0

	lsr.w	#2, d0					; Divide by 4, by shifting right 2.
									; Because when we clear the framebuffer, we write 0 as a long.

	subi.w	#1, d0					; dbra instruction will run an extra iteration for 0

ClearFramebuffer_Clear:
	move.l	#0, (a0)+				; Clear framebuffer
	dbra	d0, ClearFramebuffer_Clear

	rts

; Clear 0c00 - 9800 in VRAM, then set up Plane A nametable for framebuffer mode by sending the setup table
; to DMA queue.
InitFramebuffer:
	move.l	d2, -(sp)
	move.l	d3, -(sp)
	move.l	d4, -(sp)
	move.l	a2, -(sp)									; Open up a series of registers which will not be corrupted
														; by subsequent function calls (or at least that's not supposed to happen)

	VdpClearVram	#FRAMEBUFFER_SIZE / 2, #$0C00		; Clear area in VRAM used for second buffer
	jsr ClearFramebuffer								; Clear local copy used for first buffer

	move.w	#$0060, d4									; First entry in Plane A nametable
	move.l	#0, a2
	move.w	#VDP_TITLESCREEN_PLANE_B, a2				; Origin address of Plane A nametable

	move.w	#27, d3										; 0-27 rows in nametable
InitFramebuffer_Y:

	move.w	#39, d2										; 0-39 columns in nametable
InitFramebuffer_X:
	VdpWriteVramWord	a2, d4							; Write nametable entry
	add.w	#2, a2										; Increment nametable address
	add.w	#1, d4										; Increment nametable entry

	dbra	d2, InitFramebuffer_X						; Next column slot

	add.w	#$30, a2									; Skip 47 bytes as they go into the scroll layer
														; (It's really skipping 48 but we have it pre-incremented for us here)

	dbra	d3, InitFramebuffer_Y						; Next row

	bsr		SwapFramebuffer								; First swap of framebuffer to blank out screen

	move.l	(sp)+, a2
	move.l	(sp)+, d4
	move.l	(sp)+, d3
	move.l	(sp)+, d2
	rts

; Plot pixel at the given location.
; xx xx
; 00 yy
; 00 0c
PutPixel:
	move.l	#FRAMEBUFFER, a0

	; Deriviation and simplification of required formula:
	; cell_y = ( y / 8 )
	; 1280 * cell_y = bytes before current row
	; First we must do cell_y = floor( y / 8 ) to get an integer div value
	; cell_y = y / 8, or y >> 3.
	; Then it's just 1280 * cell_y
	; Or, ( cell_y << 10 ) + ( cell_y << 8 )

	move.l	#0, d0			; Need a long to add to a0 eventually
	move.w	6(sp), d0		; Load y to d0

	lsr.w	#3, d0			; cell_y = y / 8, or y >> 3
	move.w	d0, d1			; Copy cell_y to d1

	lsl.w	#8, d0
	lsl.w	#2, d0			; cell_y << 10

	lsl.w	#8, d1			; cell_y << 8

	add.w	d1, d0			; (cell_y << 10) + (cell_y << 8)

	; We now know which 8x8 row we're in using d0
	; Now we must take x value, get cell_x = floor( x / 8 )
	; For every x cell we move right, it's 32 bytes - 32 * cell_x or ( cell_x << 5 )
	move.w	4(sp), d1		; Load x to d0
	lsr.w	#3, d1			; cell_x = x / 8, or x >> 3
	lsl.w	#5, d1			; cell_x * 32, or cell_x << 5. Can't just do left 2 here because remainder needs to be shorn

	add.w	d1, d0			; Now add cell_x * 32 to previous result

	; We have top left of 8x8 cell. Now get position in cell using remainders
	; Just do the same exact shit here. Modulo value is n & (p - 1)
	move.w	6(sp), d1		; Reload y
	andi.w	#7, d1			; in_cell_y = y % 8, or y & 7
	lsl.w	#2, d1			; in_cell_y * 4 bytes per row, or ( in_cell_y << 2 )

	add.w	d1, d0			; Add in-cell rows to offset

	; 4bpp format means two values are packed per byte in the x-direction
	; in_cell_x = x % 8, x & 7
	; Divide in_cell_x by 2 ( in_cell_x >> 1 )
	move.w	4(sp), d1
	andi.w	#7, d1
	lsr.w	#1, d1

	add.w	d1, d0
	add.l	d0, a0			; Add the offset to framebuffer ptr

	; a0 now contains exact addr of framebuffer byte to be modified
	; if X is odd then use $F0 mask, otherwise use $0F mask
	btst.b	#0, 7(sp)
	beq		PutPixel_PixelEven

PutPixel_PixelOdd:
	andi.b	#$F0, d0	; Erase lower nibble
	or.b	9(sp), d0	; Overwrite lower nibble
	move.b	d0, (a0)	; Write the byte back to framebuffer
	bra		PutPixel_End

PutPixel_PixelEven:
	andi.b	#$0F, d0	; Erase upper nibble
	move.b	9(sp), d1
	lsl.b	#4, d1		; Shift color nibble to upper
	or.b	d1, d0		; Overwrite upper nibble
	move.b	d0, (a0)	; Write the byte back to framebuffer

PutPixel_End:
	; It's up to you to pageflip separately using SwapFramebuffer method.
	; Otherwise, pixel will not appear as it has not been sent to VDP.
	rts

; Send framebuffer to DMA queue. Framebuffer will be DMA copied RAM-to-VRAM $0C00 on next vblank.
SwapFramebuffer:
	VdpDmaQueueEnqueue	#FRAMEBUFFER_SIZE, #FRAMEBUFFER, #FRAMEBUFFER_CONTROL_WORD
	rts

	endif