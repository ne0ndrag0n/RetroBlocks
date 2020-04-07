 ifnd H_STATIC_VDP_PATTERN
H_STATIC_VDP_PATTERN = 1

  macro VdpLoadPatternDma
    move.l  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr LoadPatternDma
    PopStack 8
  endm

  macro VdpCopyVramTile
    move.l  \2, -(sp)
    move.w  \1, -(sp)
    jsr CopyVramTile
    PopStack 6
  endm

; ii ii - desired index of tile (later turned into destination address)
; nn nn - Number of 8x8 tiles to copy
; aa aa aa aa - Address of source data
LoadPatternDma:
  SetupFramePointer

  move.w  4(fp), d0         ; Multiply tile index by 32 ($20) - 8 words times 4 bytes each, per cell
  mulu.w  #$0020, d0
  move.w  d0, 4(fp)         ; 4(sp) now equals the vram destination address

  move.w  6(fp), d0         ; tiles * 16 = number of words to transfer
  mulu.w  #16, d0
  move.w  d0, 6(fp)         ; 6(sp) now equals the number of words to write

  lsr.w   #7, d0            ; >> 8
  lsr.w   #1, d0

  VdpSetRegisterRuntime 20, d0

  move.w  6(fp), d0         ; Take only the bottom bits for register 19
  andi.w  #$00FF, d0

  VdpSetRegisterRuntime 19, d0

  VdpWriteDmaSourceAddress  8(fp) ; Copy source address

  move.w  #$0080, -(sp)     ; Push settings
  move.w  4(fp), -(sp)      ; Copy vram destination address
  move.w  #0, -(sp)         ; Longword with upper as zeros
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL) ; Do the DMA (Damn Memory Access)!

  RestoreFramePointer
  rts

; Copy a tile out of VRAM into 68k RAM.
; ii ii - Index of the tile
; aa aa aa aa - Address of an 8-item long array
CopyVramTile:
  move.l  #0, d0
  move.w  4(sp), d0
  mulu.w  #32, d0           ; 32 bytes per tile

  VdpComputeDestinationAddress d0, #0001    ; Get VDP-formatted control word for VRAM read at 4(sp)
  move.l  d0, VDP_CONTROL

  move.b  #16, d1          ; Gonna be reading 16 words (32 bytes) out of VRAM
  move.l  6(sp), a0        ; Destination address goes in a0
CopyVramTile_Loop:
  move.w  VDP_DATA, (a0)

  move.l  a0, d0
  addi.l  #2, d0
  move.l  d0, a0           ; Increment a0 by 2 bytes

  dbra    d1, CopyVramTile_Loop
  rts

 endif
