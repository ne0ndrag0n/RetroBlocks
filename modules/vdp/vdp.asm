 ifnd H_STATIC_VDP
H_STATIC_VDP = 1

ClearVRAM:
  move.l  #VDP_VRAM_WRITE,(VDP_CONTROL)
  move.w  #$7FFF, d1
ClearVRAMLoop:
  move.w  #$0000, (VDP_DATA)
  dbf     d1, ClearVRAMLoop
  rts

 endif
