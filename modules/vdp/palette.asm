  ifnd H_STATIC_VDP_PALETTE
H_STATIC_VDP_PALETTE = 1

  macro VdpLoadPaletteDma
    move.l  \2, -(sp)
    move.w  \1, -(sp)
    jsr LoadPaletteDma
    PopStack 6
  endm

  macro VdpCopyPalette
    move.l  \2, -(sp)
    move.w  \1, -(sp)
    jsr CopyPalette
    PopStack 6
  endm

; 00 pp - Palette index (0-3) -> 00, 20, 40, 60
; aa aa aa aa - Source address of palette data
LoadPaletteDma:
  SetupFramePointer

  VdpSetRegister 20, 0              ; Every palette will DMA 16 words
  VdpSetRegister 19, 16

  VdpWriteDmaSourceAddress 6(fp)

  move.w  #$0082, -(sp)             ; DMA + CRAM Write
  move.w  4(fp), -(sp)              ; Copy address
  move.w  #0, -(sp)                 ; Longword with upper as zeros
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL)         ; Do the DMA

  RestoreFramePointer
  rts

; Copy a palette out of CRAM into 68k RAM.
; 00 pp - Palette index (00, 20, 40, 60)
; aa aa aa aa - Address of a 16-element word array
CopyPalette:
  ; TODO!
  rts

  endif
