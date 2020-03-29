 ifnd H_STATIC_VDP
H_STATIC_VDP = 1

VDPInitData:
  VDPDefineRegisterConstant 0, $04                                ; 04=00000100 -> 9-bit palette, everything else disabled
  VDPDefineRegisterConstant 1, $74                                ; 74=01110100 -> Genesis display mode, DMA & V-int enabled
  VDPDefineRegisterConstant 2, ( VDP_PLANE_A / $400 )             ; Plane A nametable
  VDPDefineRegisterConstant 3, ( VDP_WINDOW / $400 )              ; Window nametable
  VDPDefineRegisterConstant 4, ( VDP_PLANE_B / $2000 )            ; Plane B nametable
  VDPDefineRegisterConstant 5, ( VDP_SPRITES / $200 )             ; Sprite nametable
  VDPDefineRegisterConstant 6, $00                                ; 128kb mode stuff is always 0
  VDPDefineRegisterConstant 7, $00                                ; Set background colour to pal 0, col 0
  VDPDefineRegisterConstant 10, $00                               ; Number of lines used to generate hsync interrupt
  VDPDefineRegisterConstant 11, $00                               ; Full-screen scroll with no external interrupts
  VDPDefineRegisterConstant 12, $81                               ; 40-cell across display with no interlace
  VDPDefineRegisterConstant 13, ( VDP_HSCROLL / $400 )            ; Horizontal scroll metadata
  VDPDefineRegisterConstant 14, $00                               ; 128kb mode stuff is always 0
  VDPDefineRegisterConstant 15, $02                               ; VDP address register will always increment by 2
  VDPDefineRegisterConstant 16, ( VDP_CELL_Y << 5 | VDP_CELL_X )  ; Nametables are 64 across and 32 down
  VDPDefineRegisterConstant 17, $00                               ; Window plane horizontal position (top left)
  VDPDefineRegisterConstant 18, $00                               ; Window plane vertical position (top left)
  VDPDefineRegisterConstant 19, $FF                               ; DMA length low byte
  VDPDefineRegisterConstant 20, $FF                               ; DMA length high byte
  VDPDefineRegisterConstant 21, $00                               ; DMA address low byte
  VDPDefineRegisterConstant 22, $00                               ; DMA address mid byte
  VDPDefineRegisterConstant 23, $80                               ; DMA address high byte + type
VDPInitDataEnd:

ClearVRAM:
  move.l  #VDP_VRAM_WRITE,(VDP_CONTROL)
  move.w  #$7FFF, d1
ClearVRAMLoop:
  move.w  #$0000, (VDP_DATA)
  dbf     d1, ClearVRAMLoop
  rts

 endif
