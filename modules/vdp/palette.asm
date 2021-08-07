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

  macro VdpFindPaletteEntry
    move.l  \2, -(sp)
    move.w  \1, -(sp)
    jsr FindPaletteEntry
    PopStack 6
  endm

  macro VdpCopyRomPalette
    move.l \2, -(sp)
    move.l \1, -(sp)
    jsr CopyRomPalette
    PopStack 8
  endm

; **Deprecated** Use VdpDmaQueueEnqueue with CRAM destination
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

  VdpSendCommandLong  d0            ; Do the DMA

  RestoreFramePointer
  rts

; Copy a palette out of CRAM into 68k RAM.
; 00 pp - Palette index (00, 20, 40, 60)
; aa aa aa aa - Address of a 16-element word array
CopyPalette:
  move.w  4(sp), d0
  VdpGetControlWord d0, #VDP_CRAM_READ

  VdpSendCommandLong  d0

  move.w  #15, d1     ; d1 = counter for how many words to read
  move.l  6(sp), a0   ; a0 = destination array
CopyPalette_Loop:
  move.w  (VDP_DATA), (a0)+
  dbra    d1, CopyPalette_Loop
  rts

; Given a palette and a colour word, find the index of the entry.
; cc cc - Colour entry to find
; aa aa aa aa - Address of a 16-colour array.
; Returns: 00 ii - Index, or -1 if entry not found.
FindPaletteEntry:
  move.w  #15, d1     ; d1 = counter for array
  move.l  6(sp), a0   ; a0 = haystack
                      ; 4(sp) = needle
FindPaletteEntry_Loop:
  move.w  (a0)+, d0
  cmp.w   4(sp), d0
  beq.s   FindPaletteEntry_Found
  dbra    d1, FindPaletteEntry_Loop

FindPaletteEntry_NotFound:
  move.w  #-1, d0
  rts

FindPaletteEntry_Found:
  ; Return 16 - d1
  move.w  #16, d0
  sub.w   d1, d0
  rts

; Copy a palette in ROM to a location in RAM.
; ss ss ss ss - Source palette
; dd dd dd dd - Destination array (32 bytes)
CopyRomPalette:
  move.w  #8, d0

  move.l  4(sp), a0   ; Source pointer
  move.l  8(sp), a1   ; Destination pointer
CopyRomPalette_Loop:
  move.l  (a0)+, (a1)+
  dbeq  d0, CopyRomPalette_Loop
  rts

  endif
