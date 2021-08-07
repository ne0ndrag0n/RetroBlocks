	ifnd H_VDP_STATES
H_VDP_STATES = 1

VdpTitlescreenState:
VDP_TITLESCREEN_PLANE_A=$C000
VDP_TITLESCREEN_PLANE_B=$E000
VDP_TITLESCREEN_WINDOW=$D000
VDP_TITLESCREEN_SPRITES=$B800
VDP_TITLESCREEN_SPRITE_METADATA=VDP_TITLESCREEN_SPRITES - 16
VDP_TITLESCREEN_HSCROLL=$BC00
VDP_TITLESCREEN_PLANE_CELLS_H=64
VDP_TITLESCREEN_PLANE_CELLS_V=32

  if VDP_TITLESCREEN_PLANE_CELLS_H == 32
VDP_TITLESCREEN_CELL_X = $00
  else
  if VDP_TITLESCREEN_PLANE_CELLS_H == 64
VDP_TITLESCREEN_CELL_X = $01
  else
  if VDP_TITLESCREEN_PLANE_CELLS_H == 128
VDP_TITLESCREEN_CELL_X = $11
  else
  fail "VDP_TITLESCREEN_PLANE_CELLS_H must be one of 32, 64, or 128"
  endif
  endif
  endif

  if VDP_TITLESCREEN_PLANE_CELLS_V == 32
VDP_TITLESCREEN_CELL_Y = $00
  else
  if VDP_TITLESCREEN_PLANE_CELLS_V == 64
VDP_TITLESCREEN_CELL_Y = $01
  else
  if VDP_TITLESCREEN_PLANE_CELLS_V == 128
VDP_TITLESCREEN_CELL_Y = $11
  else
  fail "VDP_TITLESCREEN_PLANE_CELLS_V must be one of 32, 64, or 128"
  endif
  endif
  endif

VDP_TITLESCREEN_VIDEO_MODE = VDP_MEGADRIVE | VDP_DMA_ENABLED | VDP_VBLANK_ENABLED | VDP_SCREEN_ENABLED

  VdpDefineRegisterConstant 0, $04                                	; 04=00000100 -> 9-bit palette, everything else disabled
  VdpDefineRegisterConstant 1, VDP_TITLESCREEN_VIDEO_MODE          	; 74=01110100 -> Genesis display mode, DMA & V-int enabled
  VdpDefineRegisterConstant 2, ( VDP_TITLESCREEN_PLANE_A / $400 )   ; Plane A nametable
  VdpDefineRegisterConstant 3, ( VDP_TITLESCREEN_WINDOW / $400 )    ; Window nametable
  VdpDefineRegisterConstant 4, ( VDP_TITLESCREEN_PLANE_B / $2000 )  ; Plane B nametable
  VdpDefineRegisterConstant 5, ( VDP_TITLESCREEN_SPRITES / $200 )   ; Sprite nametable
  VdpDefineRegisterConstant 6, $00                                	; 128kb mode stuff is always 0
  VdpDefineRegisterConstant 7, $00                                	; Set background colour to pal 0, col 0
  VdpDefineRegisterConstant 10, $00                               	; Number of lines used to generate hsync interrupt
  VdpDefineRegisterConstant 11, $00                               	; Full-screen scroll with no external interrupts
  VdpDefineRegisterConstant 12, $81                               	; 40-cell across display with no interlace
  VdpDefineRegisterConstant 13, ( VDP_TITLESCREEN_HSCROLL / $400 )  ; Horizontal scroll metadata
  VdpDefineRegisterConstant 14, $00                               	; 128kb mode stuff is always 0
  VdpDefineRegisterConstant 15, $02                               	; VDP address register will always increment by 2
  VdpDefineRegisterConstant 16, ( VDP_TITLESCREEN_CELL_Y << 5 | VDP_TITLESCREEN_CELL_X )  ; Nametables are 64 across and 32 down
  VdpDefineRegisterConstant 17, $00                               	; Window plane horizontal position (top left)
  VdpDefineRegisterConstant 18, $00                               	; Window plane vertical position (top left)
  VdpDefineRegisterConstant 19, $FF                               	; DMA length low byte
  VdpDefineRegisterConstant 20, $FF                               	; DMA length high byte
  VdpDefineRegisterConstant 21, $00                               	; DMA address low byte
  VdpDefineRegisterConstant 22, $00                               	; DMA address mid byte
  VdpDefineRegisterConstant 23, $80                               	; DMA address high byte + type
VdpTitlescreenState_End:

VdpGameplayState:
VDP_GAMEPLAY_PLANE_A = $C000
VDP_GAMEPLAY_PLANE_B = $E000
VDP_GAMEPLAY_WINDOW  = $A000
VDP_GAMEPLAY_SPRITES = $9E00
VDP_GAMEPLAY_HSCROLL = $9C00
VDP_BLOCKTILE_METADATA = $7C00

VDP_GAMEPLAY_PLANE_CELLS_H = 64
VDP_GAMEPLAY_PLANE_CELLS_V = 64
VDP_GAMEPLAY_CELL_X = $01
VDP_GAMEPLAY_CELL_Y = $01

  VdpDefineRegisterConstant 2, ( VDP_GAMEPLAY_PLANE_A / $400 )   ; Plane A nametable
  VdpDefineRegisterConstant 3, ( VDP_GAMEPLAY_WINDOW / $400 )    ; Window nametable
  VdpDefineRegisterConstant 4, ( VDP_GAMEPLAY_PLANE_B / $2000 )  ; Plane B nametable
  VdpDefineRegisterConstant 5, ( VDP_GAMEPLAY_SPRITES / $200 )   ; Sprite nametable
  VdpDefineRegisterConstant 13, ( VDP_GAMEPLAY_HSCROLL / $400 )  ; Horizontal scroll metadata
  VdpDefineRegisterConstant 16, ( VDP_GAMEPLAY_CELL_Y << 5 | VDP_GAMEPLAY_CELL_X )  ; Nametables are 64 across and 64 down
VdpGameplayState_End:

	macro VdpSendCommandList
		move.w	\2, -(sp)
		move.l	\1, -(sp)
		jsr	_VdpSendCommandList
		PopStack 6
	endm

; Send a list of commands to the VDP
; aa aa aa aa - Array of command list
; cc cc - Number of words in the command list
_VdpSendCommandList:
	move.w	8(sp), d0		; d0 = number of commands
	move.l	4(sp), a0		; a0 = origin address
_VdpSendCommandList_NextCommand:
	VdpSendCommandWord	(a0)+					; Send command
	dbf		d0, _VdpSendCommandList_NextCommand		; Decrement and branch if it's 0
	rts

	endif