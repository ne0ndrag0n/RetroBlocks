 ifnd H_STATIC_VDP_NAMETABLE
H_STATIC_VDP_NAMETABLE = 1
  include 'modules/static_vdp/util.asm'

  macro VdpBlitRepeatingPattern
    move.w  \6, -(sp)
    move.w  \5, -(sp)
    move.w  \4, -(sp)
    move.w  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr BlitRepeatingPattern
    PopStack 12
  endm

  macro VdpErasePlane
    move.w \1, -(sp)
    jsr ErasePlane
    PopStack 2
  endm

  macro VdpBlitFill
    move.w  \5, -(sp)
    move.w  \4, -(sp)
    move.w  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr BlitFill
    PopStack 10
  endm

VDP_TILE_ATTR_PAL0 = $00
VDP_TILE_ATTR_PAL1 = $20
VDP_TILE_ATTR_PAL2 = $40
VDP_TILE_ATTR_PAL3 = $60
VDP_TILE_ATTR_PRIORITY = $80

; TODO: Callee-saved d2 register for gcc compatibility
; xx yy - Location on plane
; ww hh - Width and height of pattern
; rr rr - Root pattern index (8x8 numeric index, not address)
; pp pp - Root plane address
; 00 aa - Tile attribute (priority (1), palette (2), vflip (1), hflip (1))
BlitPattern:
  ; calculate vdp nametable address using [pp pp] and [xx yy]
  ; for each hh
  ; shift around and write vdp nametable address
  ;   for each ww
  ;   write index [rr rr] to vdp control word using [aa] attributes (vdp will autoincrement one word)
  ;   increment [rr rr]
  ; step by pw

  move.l  #0, d0
  move.l  #0, d1
  move.l  #0, d2

  move.b  5(sp), d2                   ; move yy into d2

  mulu.w  #VDP_PLANE_CELLS_H, d2      ; yy * VDP_PLANE_CELLS_H

  move.b  4(sp), d0
  add.w   d0, d2                      ; + xx

  mulu.w  #$0002, d2                  ; times 2 - d2 now contains cell number

  add.w   10(sp), d2                  ; d2 now contains actual plane address
                                      ; save this to increment and format for vdp control long

BlitPattern_ForEachHH:
  move.b  7(sp), d0                   ; Break if hh is zero
  tst.b   d0
  beq.s   BlitPattern_ForEachHHEnd

  move.b  7(sp), d0                   ; Decrement hh
  subi.b  #$01, d0
  move.b  d0, 7(sp)

  move.l  #VDP_VRAM_WRITE, d0         ; Here we format the VDP control longword
  move.l  d2, d1
  andi.w  #$3FFF, d1                  ; address & $3FFF
  lsl.l   #7, d1
  lsl.l   #7, d1
  lsl.l   #2, d1                      ; << 16
  or.l    d1, d0                      ; VDP_VRAM_WRITE | ( ( address & $3FFF ) << 16 )

  move.l  d2, d1
  andi.w  #$C000, d1                  ; address & $C000
  lsr.w   #7, d1
  lsr.w   #7, d1                      ; >> 14
  or.l    d1, d0                      ; VDP_VRAM_WRITE | ( ( address & $C000 ) >> 14 )

  move.l  d0, (VDP_CONTROL)

  move.b  6(sp), d1                   ; d1 = ww

BlitPattern_ForEachWW:
  tst.b   d1                          ; Stop when d1 is 0
  beq.s   BlitPattern_ForEachWWEnd

  subi.b  #$01, d1                    ; d1--

  move.w  12(sp), d0                  ; d0 = aa << 8
  lsl.w   #$07, d0
  lsl.w   #$01, d0

  or.w    8(sp), d0                   ; d0 = d0 | rr rr

  move.w  d0, (VDP_DATA)              ; Write tile index + settings to plane nametable
                                      ; VDP shall autoincrement by 1 word

  move.w  8(sp), d0                   ; (rr rr)++
  addi.w  #$01, d0
  move.w  d0, 8(sp)

  bra.s   BlitPattern_ForEachWW
BlitPattern_ForEachWWEnd:

  move.w  #( $0000 | VDP_PLANE_CELLS_H ), d0      ; advance d2 by (row * 2)
  lsl.w   #1, d0
  add.w   d0, d2

  bra.s   BlitPattern_ForEachHH
BlitPattern_ForEachHHEnd:
  rts

; Fills a ww*hh region at xx,yy with only one kind of tile
; d2 d2 d2 d2 - Save the d2 address for ABI compatibility with C
; rr rr rr rr
; xx yy - Location on plane
; ww hh - Width and height of fill
; rr rr - Desired pattern index
; pp pp - Root plane address
; 00 aa - Tile attribute (priority (1), palette (2), vflip (1), hflip (1))
BlitFill:
  move.l  d2, -(sp)

  move.l  #0, d0
  move.l  #0, d1
  move.l  #0, d2

  move.b  9(sp), d2                   ; move yy into d2

  mulu.w  #VDP_PLANE_CELLS_H, d2      ; yy * VDP_PLANE_CELLS_H

  move.b  8(sp), d0
  add.w   d0, d2                      ; + xx

  mulu.w  #$0002, d2                  ; times 2 - d2 now contains cell number

  add.w   14(sp), d2                  ; d2 now contains actual plane address
                                      ; save this to increment and format for vdp control long

  move.w  16(sp), d0                   ; d0 = aa << 8
  lsl.w   #$07, d0
  lsl.w   #$01, d0

  or.w    12(sp), d0                   ; d0 | rr rr
  move.w  d0, 12(sp)                   ; Save attributes over given tile index

BlitFill_ForEachHH:
  move.b  11(sp), d0                   ; Break if hh is zero
  tst.b   d0
  beq.s   BlitFill_ForEachHHEnd

  move.b  11(sp), d0                   ; Decrement hh
  subi.b  #$01, d0
  move.b  d0, 11(sp)

  move.w  #0, -(sp)                    ; call ComputeVdpDestinationAddress
  move.l  d2, -(sp)
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  d0, (VDP_CONTROL)

  move.b  10(sp), d1                   ; d1 = ww

BlitFill_ForEachWW:
  tst.b   d1                          ; Stop when d1 is 0
  beq.s   BlitFill_ForEachWWEnd

  subi.b  #$01, d1                    ; d1--

  move.w  12(sp), (VDP_DATA)          ; Write tile w/attributes

  bra.s BlitFill_ForEachWW
BlitFill_ForEachWWEnd:

  move.w  #( $0000 | VDP_PLANE_CELLS_H ), d0      ; advance d2 by (row * 2)
  lsl.w   #1, d0
  add.w   d0, d2

  bra.s BlitFill_ForEachHH
BlitFill_ForEachHHEnd:

  move.l  (sp)+, d2                  ; Restore d2
  rts

; xx yy - Location on plane
; rr rr - Desired pattern index
; pp pp - Root plane address
; 00 aa - Tile attribute (priority (1), palette (2), vflip (1), hflip (1))
BlitSingleTile:
  move.w  #0, -(sp)         ; vram write no dma
  move.w  10(sp), -(sp)     ; Copy plane nametable vram address
  move.w  8(sp), -(sp)      ; Copy desired location on nametable
  jsr WriteVDPNametableLocation
  PopStack 6

  move.l  #0, d1

  move.w  10(sp), d1        ; attribute << 8
  lsl.w   #7, d1
  lsl.w   #1, d1

  or.w    6(sp), d1         ; OR the desired nametable item

  move.l  d1, (VDP_DATA)    ; Write to the vdp
  rts

; xx yy - Location on plane
; ww hh - Width and height of pattern
; rr rr - Root pattern index (8x8 numeric index, not address)
; pp pp - Root plane address
; 00 aa - Tile attribute (priority (1), palette (2), vflip (1), hflip (1))
; dw dh - Repeat dimensions
BlitRepeatingPattern:
  SetupFramePointer

  ; All the weirdness here is because stack shit needs to be word-aligned
  move.w  #0, -(sp)           ; -6(fp) = Hold place for copies of dw
  move.w  4(fp), -(sp)        ; -8(fp) = Counter for drawn items x & y

BlitRepeatingPattern_ForEachDh:
  tst.b   15(fp)              ; See if we're out of dh
  beq.s   BlitRepeatingPattern_EndDh

  subi.b  #1, 15(fp)          ; Decrement by one

  move.b  14(fp), -5(fp)      ; Copy dw

BlitRepeatingPattern_ForEachDw:
  tst.w   -6(fp)              ; See if we're out of dw
  beq.s   BlitRepeatingPattern_EndDw

  subi.w  #1, -6(fp)          ; Decrement by one

  VdpBlitPattern -8(fp), 6(fp), 8(fp), 10(fp), 12(fp)

  move.b  -8(fp), d0          ; Increment xx by one ww
  add.b   6(fp), d0
  move.b  d0, -8(fp)

  bra.s   BlitRepeatingPattern_ForEachDw
BlitRepeatingPattern_EndDw:

  move.b  4(fp), -8(fp)       ; Reset temporary xx to normal xx

  move.b  -7(fp), d0          ; Increment yy by one hh
  add.b   7(fp), d0
  move.b  d0, -7(fp)

  bra.s   BlitRepeatingPattern_ForEachDh
BlitRepeatingPattern_EndDh:

  PopStack 4                  ; Deallocate local variables
  RestoreFramePointer
  rts

; pp pp - Root plane address
ErasePlane:
  VDPSetRegister 15, 1                  ; Increment per byte

  VDPSetRegister 20, $10                ; $1000 bytes
  VDPSetRegister 19, $00

  VDPSetRegister 23, $80                ; I think we need to set this?
  VDPSetRegister 22, $00
  VDPSetRegister 21, $00

  move.l  #0, d0                        ; Construct argument for VdpComputeDestinationAddress
  move.w  4(sp), d0

  move.w  #( VDP_DEST_VRAM_WRITE | VDP_DEST_DMA ), d1

  VdpComputeDestinationAddress d0, d1

  move.l  d0, (VDP_CONTROL)             ; Do the DMA
  move.w  #0, (VDP_DATA)                ; VRAM fill of $0800 "0000" words to the specified plane

  VDPSetRegister 15, 2                  ; Put it back - Most static VDP operations assume word increment
  rts

 endif
