  ifnd H_STATIC_VDP_PALETTE
H_STATIC_VDP_PALETTE = 1

; 00 pp - Palette index (0-3) -> 00, 20, 40, 60
; aa aa aa aa - Source address of palette data
LoadPaletteDma:
  SetupFramePointer

  VDPSetRegister 20, 0              ; Every palette will DMA 16 words
  VDPSetRegister 19, 16

  VdpWriteDmaSourceAddress 6(fp)

  move.w  #$0082, -(sp)             ; DMA + CRAM Write
  move.w  4(fp), -(sp)              ; Copy address
  move.w  #0, -(sp)                 ; Longword with upper as zeros
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL)         ; Do the DMA

  RestoreFramePointer
  rts

  endif
