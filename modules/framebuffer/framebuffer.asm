	ifnd H_FRAMEBUFFER
H_FRAMEBUFFER = 1

	macro FramebufferPutPixel
		move.l \1, -(sp)
		jsr PutPixel
		PopStack 4
	endm

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
; 0c xx xx yy - Desired colour, X coordinate, y coordinate
PutPixel:
	move.l	4(sp), d0
	andi.l	#$00FFFFFF, d0 		; Shear off the colour value
	lsl.l	#1, d0				; Index * 2 - must be word index

	move.l	#FramebufferPutPixelTable, a0

	move.l	#$00FF0000, a1
	move.w	(a0, d0), d1		; Lookup target lower RAM word into d1

	move.b	(a1, d1.w), d0		; Load target byte out of framebuffer into d0

	; (a1, d1.w) now contains exact addr of framebuffer byte to be modified
	; if X is odd then use $F0 mask, otherwise use $0F mask
	btst.b	#0, 6(sp)
	beq		PutPixel_PixelEven

PutPixel_PixelOdd:
	andi.b	#$F0, d0		; Erase lower nibble
	or.b	4(sp), d0		; Overwrite lower nibble
	move.b	d0, (a1, d1.w)	; Write the byte back to framebuffer
	rts

PutPixel_PixelEven:
	add.w	d1, a1		; We are going to need d1 here so free it up
	andi.b	#$0F, d0	; Erase upper nibble
	move.b	4(sp), d1
	lsl.b	#4, d1		; Shift color nibble to upper
	or.b	d1, d0		; Overwrite upper nibble
	move.b	d0, (a1)	; Write the byte back to framebuffer
	rts

; Send framebuffer to DMA queue. Framebuffer will be DMA copied RAM-to-VRAM $0C00 on next vblank.
SwapFramebuffer:
	VdpDmaQueueEnqueue	#FRAMEBUFFER_SIZE, #FRAMEBUFFER, #FRAMEBUFFER_CONTROL_WORD
	rts

	endif