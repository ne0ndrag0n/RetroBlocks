 ifnd H_STATIC_VDP_CONSTANTS
H_STATIC_VDP_CONSTANTS = 1

  ; 0 = 128 for any given sprite value
  ; To go from real to retarded sprite coordinates, add 128/$80

  macro VDPDefineRegisterConstant
    dc.w ( ( $80 + \1 ) << 8 ) | \2
  endm

  macro VDPSetRegister
    move.w #( ( ( $80 + \1 ) << 8 ) | \2 ), (VDP_CONTROL)
  endm

  macro VDPSetRegisterRuntime
    move.w  #$0080, d1
    addi.w  #\1, d1
    lsl.w   #7, d1
    lsl.w   #1, d1
    or.b    \2, d1
    move.w  d1, (VDP_CONTROL)
  endm

  macro VdpLoadPaletteDma
    move.l  \2, -(sp)
    move.w  \1, -(sp)
    jsr LoadPaletteDma
    PopStack 6
  endm

  macro VdpLoadPatternDma
    move.l  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr LoadPatternDma
    PopStack 8
  endm

  macro VdpBlitPattern
    move.w  \5, -(sp)
    move.w  \4, -(sp)
    move.w  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr BlitPattern
    PopStack 10
  endm

  macro VdpDrawText
    move.l  \2, -(sp)
    move.w  \1, -(sp)
    jsr DrawText
    PopStack 6
  endm

; VDP is currently structured to be fully static
VDP_PLANE_A=$C000
VDP_PLANE_B=$E000
VDP_WINDOW=$D000
VDP_SPRITES=$B800
VDP_SPRITE_METADATA=VDP_SPRITES - 16
VDP_HSCROLL=$BC00
VDP_PLANE_CELLS_H=64
VDP_PLANE_CELLS_V=32

  if VDP_PLANE_CELLS_H == 32
VDP_CELL_X = $00
  else
  if VDP_PLANE_CELLS_H == 64
VDP_CELL_X = $01
  else
  if VDP_PLANE_CELLS_H == 128
VDP_CELL_X = $11
  else
  fail "VDP_PLANE_CELLS_H must be one of 32, 64, or 128"
  endif
  endif
  endif

  if VDP_PLANE_CELLS_V == 32
VDP_CELL_Y = $00
  else
  if VDP_PLANE_CELLS_V == 64
VDP_CELL_Y = $01
  else
  if VDP_PLANE_CELLS_V == 128
VDP_CELL_Y = $11
  else
  fail "VDP_PLANE_CELLS_V must be one of 32, 64, or 128"
  endif
  endif
  endif

; VDP access modes
VDP_CRAM_READ=$20000000
VDP_CRAM_WRITE=$C0000000
VDP_VRAM_READ=$00000000
VDP_VRAM_WRITE=$40000000
VDP_VSRAM_READ=$10000000
VDP_VSRAM_WRITE=$14000000
VDP_DMA_ADDRESS=$00000080

; VDP status
VDP_STATUS_FIFO_EMPTY=$0200
VDP_STATUS_FIFO_FULL=$0100
VDP_STATUS_VINT_PENDING=$0080
VDP_STATUS_SPRITE_OVERFLOW=$0040
VDP_STATUS_SPRITE_COLLISION=$0020
VDP_STATUS_ODD_FRAME=$0010
VDP_STATUS_VBLANK=$0008
VDP_STATUS_HBLANK=$0004
VDP_STATUS_DMA=$0002
VDP_STATUS_PAL=$0001

VDP_DATA=$00C00000
VDP_CONTROL=$00C00004
VDP_HVCOUNTER=$00C00008

VDP_PAL_0=$00
VDP_PAL_1=$20
VDP_PAL_2=$40
VDP_PAL_3=$60

 endif
