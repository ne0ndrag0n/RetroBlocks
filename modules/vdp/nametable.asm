 ifnd H_STATIC_VDP_NAMETABLE
H_STATIC_VDP_NAMETABLE = 1
  include 'modules/vdp/util.asm'

  macro VdpErasePlane
    move.w \1, -(sp)
    jsr ErasePlane
    PopStack 2
  endm

  macro VdpBlitPattern
    move.w  \6, -(sp)
    move.w  \5, -(sp)
    move.w  \4, -(sp)
    move.w  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr BlitPattern
    PopStack 12
  endm

  macro VdpGetNametableEntry
    move.w \2, -(sp)
    move.w \1, -(sp)
    jsr GetNametableEntry
    PopStack 4
  endm

  macro VdpGetTileId
    move.w  \1, d0
    andi.w  #$07FF, d0
  endm

  macro VdpGetPaletteId
    move.w  \1, d0
    andi.w  #$6000, d0
    lsr.w   #8, d0
    lsr.w   #5, d0
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
; pw pw - Plane width
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

  mulu.w  12(sp), d2                  ; yy * pw

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

  move.w  14(sp), d0                  ; d0 = aa << 8
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

  move.w  12(sp), d0      ; advance d2 by (row * 2)
  lsl.w   #1, d0
  add.w   d0, d2

  bra.s   BlitPattern_ForEachHH
BlitPattern_ForEachHHEnd:
  rts

; pp pp - Root plane address
ErasePlane:
  VdpSetRegister 15, 1                  ; Increment per byte

  VdpSetRegister 20, $10                ; $1000 bytes
  VdpSetRegister 19, $00

  VdpSetRegister 23, $80                ; I think we need to set this?
  VdpSetRegister 22, $00
  VdpSetRegister 21, $00

  move.l  #0, d0                        ; Construct argument for VdpComputeDestinationAddress
  move.w  4(sp), d0

  move.w  #( VDP_DEST_VRAM_WRITE | VDP_DEST_DMA ), d1

  VdpComputeDestinationAddress d0, d1

  move.l  d0, (VDP_CONTROL)             ; Do the DMA
  move.w  #0, (VDP_DATA)                ; VRAM fill of $0800 "0000" words to the specified plane

  VdpSetRegister 15, 2                  ; Put it back - Most static VDP operations assume word increment
  rts

; Get a specific nametable entry for an x,y coordinate on the specified plane.
; xx yy - Plane coordinates
; pp pp - Plane address in VRAM
; Returns: ww ww - Nametable word
GetNametableEntry:
  SetupFramePointer

  move.w  #0, -(sp)   ; 2(sp) - y
  move.w  #0, -(sp)   ; (sp) - x

  move.b  4(fp), 1(sp)
  move.b  5(fp), 3(sp)

	; Formula: VDP_GAMEPLAY_PLANE_A/B + ( 128 * y ) + ( 2 * x )

  move.w  2(sp), d0
  mulu.w  #128, d0
  move.w  d0, 2(sp)    ; y = y * 128

  move.w  (sp), d0
  mulu.w  #2, d0
  move.w  d0, (sp)     ; x = x * 2

  move.w  (sp), d0
  add.w   2(sp), d0   ; ( 128 * y ) + ( 2 * x )
  add.w   6(fp), d0   ; + nametable_address

  VdpReadVramWord  d0

  PopStack 4
  RestoreFramePointer
  rts

 endif
