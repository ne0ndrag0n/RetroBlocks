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

	VdpClearVram	#FRAMEBUFFER_SIZE / 2, #$0C00		; Clear area in VRAM used for second buffer
	jsr ClearFramebuffer								; Clear local copy used for first buffer

	move.w	#$0060, d0									; First entry in Plane A nametable
	move.l	#0, a0
	move.w	#$0C00, a0									; Origin address of Plane A nametable

	move.w	#27, d1										; 0-27 rows in nametable
InitFramebuffer_Y:

	move.w	#39, d2										; 0-39 columns in nametable
InitFramebuffer_X:

	VdpWriteVramWord	a0, d0							; Write nametable entry
	add.w	#2, a0										; Increment nametable address
	add.w	#1, d0										; Increment nametable entry

	dbra	d2, InitFramebuffer_X						; Next column slot

	add.w	#(23*2), a0									; Ignore remaining 24 columns and skip to next row
														; (Each column is one word, and we are already advanced one word)

	dbra	d1, InitFramebuffer_Y						; Next row

	move.l	(sp)+, d2
	rts

; Plot pixel at the given location.
; xx xx yy 0c - X-location, Y-location, and desired colour.
PutPixel:
	rts

; Send framebuffer to DMA queue. Framebuffer will be DMA copied RAM-to-VRAM $0C00 on next vblank.
SwapFramebuffer:
	rts

	endif