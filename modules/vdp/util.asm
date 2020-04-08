 ifnd H_STATIC_VDP_UTIL
H_STATIC_VDP_UTIL = 1
 include 'modules/helpers/stack.asm'

 macro VdpComputeDestinationAddress
  move.w  \2, -(sp)
  move.l  \1, -(sp)
  jsr ComputeVdpDestinationAddress
  PopStack 6
 endm

 macro VdpGetControlWord
  move.l \2, -(sp)
  move.w \1, -(sp)
  move.w #0, -(sp)
  jsr GetVdpControlWord
  PopStack 8
 endm

 macro VdpWriteDmaSourceAddress
  move.l \1, -(sp)
  jsr WriteDmaSourceAddress
  PopStack 4
 endm

  macro VdpDefineRegisterConstant
    dc.w ( ( $80 + \1 ) << 8 ) | \2
  endm

  macro VdpSetRegisterRuntime
    move.w  #$0080, d1
    addi.w  #\1, d1
    lsl.w   #7, d1
    lsl.w   #1, d1
    or.b    \2, d1
    move.w  d1, (VDP_CONTROL)
  endm

  macro VdpSetRegister
    move.w #( ( ( $80 + \1 ) << 8 ) | \2 ), (VDP_CONTROL)
  endm

 macro VdpEnableDma
    VdpSetRegister  1, VDP_DMA_ENABLED
 endm

 macro VdpDisableDma
    VdpSetRegister  1, VDP_DMA_DISABLED
 endm

  macro VdpClearVram
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr ClearVram
    PopStack 4
  endm

  macro VdpWriteNametableLocation
    move.w \4, -(sp)
    move.w \3, -(sp)
    move.w \2, -(sp)
    move.w \1, -(sp)
    jsr WriteVDPNametableLocation
    PopStack 8
  endm

  macro VdpReadVramWord
    move.w \1, -(sp)
    jsr ReadVramWord
    PopStack 2
  endm

  macro VdpWriteVramWord
    move.w \2, -(sp)
    move.w \1, -(sp)
    jsr WriteVramWord
    PopStack 4
  endm

VDP_DEST_VRAM_WRITE=$00
VDP_DEST_VRAM_READ=$01
VDP_DEST_CRAM_WRITE=$02
VDP_DEST_DMA=$80

VDP_DMA_VRAM_FILL=$80

; xx yy - Tile index
; pp pp - Plane nametable VRAM address
; 00 hh - Horizontal dimension of nametable
; 00 ss - Status, in bits: 0000 0000 for vram write, 0000 0001 for vram read, 1000 0000 for DMA
; Returns: Computed nametable address
WriteVDPNametableLocation:
  move.l  #$0, d0                       ; clear d0 and d1
  move.l  #$0, d1

  ; 2( hh * yy ) + xx

  move.b  5(sp), d0                     ; move yy into d0

  mulu.w  8(sp), d0                     ; yy * hh

  move.b  4(sp), d1
  add.w   d1, d0                        ; + xx

  lsl.w   #1, d0                        ; times 2
                                        ; d0 now contains cell number

  add.w   6(sp), d0                     ; d0 now contains address

  move.w  10(sp), -(sp)                 ; Copy status
  move.l  d0, -(sp)                     ; push vram address onto stack
  bsr.s   ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL)             ; Write VDP control word containing VRAM address
  rts

; ** Deprecated ** use GetVdpControlWord
; 00 00 pp pp - Destination VRAM address
; 00 ss - Status, in bits: 0000 0000 for vram write, 0000 0001 for vram read, 0000 0010 for cram write, 1000 0000 for DMA
; Returns: Computed nametable address
ComputeVdpDestinationAddress:
  move.w  8(sp), d1                                 ; Check for VRAM Read
  btst    #0, d1                                    ; If bit 0 is clear
  beq.s   ComputeVdpDestinationAddress_CheckCram    ; it's CRAM or VRAM write

  move.l  #VDP_VRAM_READ, d0
  bra.s   ComputeVdpDestinationAddress_CheckDMA

ComputeVdpDestinationAddress_CheckCram:
  btst    #1, d1                                    ; Check for CRAM write - if bit 1 is clear
  beq.s   ComputeVdpDestinationAddress_WriteVram    ; it's VRAM write

  move.l  #VDP_CRAM_WRITE, d0
  bra.s   ComputeVdpDestinationAddress_CheckDMA

ComputeVdpDestinationAddress_WriteVram:
  move.l  #VDP_VRAM_WRITE, d0

ComputeVdpDestinationAddress_CheckDMA:
  btst    #7, d1                        ; Check if DMA is being applied
  beq.s   ComputeVdpDestinationAddress_WriteAddress

  move.l  #VDP_DMA_ADDRESS, d1          ; OR the DMA bits
  or.l    d1, d0

ComputeVdpDestinationAddress_WriteAddress:
  move.l  4(sp), d1
  andi.w  #$3FFF, d1                    ; address & $3FFF
  lsl.l   #$07, d1
  lsl.l   #$07, d1
  lsl.l   #$02, d1                      ; << 16
  or.l    d1, d0                        ; VDP_VRAM_WRITE | ( ( address & $3FFF ) << 16 )

  move.l  4(sp), d1
  andi.w  #$C000, d1                    ; address & $C000
  lsr.w   #$07, d1
  lsr.w   #$07, d1                      ; >> 14
  or.l    d1, d0                        ; ... | ( ( address & $C000 ) >> 14 )
  rts

; Get the control word for a given VRAM address and VDP operation
; 00 00 pp pp - Destination VRAM address
; ss ss ss ss - VRAM status longword
GetVdpControlWord:
  move.l  8(sp), d0                     ; base options

  move.l  4(sp), d1
  andi.w  #$3FFF, d1                    ; address & $3FFF
  lsl.l   #$07, d1
  lsl.l   #$07, d1
  lsl.l   #$02, d1                      ; << 16
  or.l    d1, d0                        ; VDP_VRAM_WRITE | ( ( address & $3FFF ) << 16 )

  move.l  4(sp), d1
  andi.w  #$C000, d1                    ; address & $C000
  lsr.w   #$07, d1
  lsr.w   #$07, d1                      ; >> 14
  or.l    d1, d0                        ; ... | ( ( address & $C000 ) >> 14 )
  rts

; aa aa aa aa - Source address for VDP DMA
WriteDmaSourceAddress:
  move.l  4(sp), d0                     ; Fetch source address and divide by 2
  lsr.l   #1, d0
  move.l  d0, 4(sp)

  andi.l  #$007F0000, d0                ; Take only the top byte
  lsr.l   #7, d0                        ; >> 16
  lsr.l   #7, d0
  lsr.l   #2, d0

  VdpSetRegisterRuntime 23, d0

  move.l  4(sp), d0                     ; Write middle byte
  andi.l  #$0000FF00, d0                ; Take only middle bits
  lsr.l   #7, d0                        ; >> 8
  lsr.l   #1, d0

  VdpSetRegisterRuntime 22, d0

  move.l  4(sp), d0                     ; Write lower byte
  andi.l  #$000000FF, d0                ; Take only lower byte

  VdpSetRegisterRuntime 21, d0
  rts

; aa aa - VRAM address
; Returns: Word value at address
ReadVramWord:
  move.w  #$0001, -(sp)   ; Set vram read
  move.w  6(sp), -(sp)
  move.w  #0, -(sp)
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL)

  move.w  VDP_DATA, d0    ; Read from vdp
  rts

; aa aa - VRAM address
; ww ww - Contents to write
WriteVramWord:
  move.w  #$0000, -(sp)
  move.w  6(sp), -(sp)
  move.w  #0, -(sp)
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL)

  move.w  6(sp), (VDP_DATA)
  rts

; Clears VRAM beginning at the specified region and lasting until the given count
; cc cc - Byte clear count
; oo oo - Origin VRAM address
ClearVram:
  move.w  #0, -(sp)
  move.w  6 + 2(sp), -(sp)
  move.w  #0, -(sp)
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL)

  move.w  4(sp), d0
ClearVram_Loop:
  move.w  #0, (VDP_DATA)
  dbf.w   d0, ClearVram_Loop
  rts

 endif
