 ifnd H_STATIC_VDP_TEXT
H_STATIC_VDP_TEXT = 1

  include 'modules/helpers/stack.asm'

  macro VdpDrawText
    move.l  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr DrawText
    PopStack 8
  endm

; Coordinates: xx yy
; Plane: pp pp
; String address: ss ss ss ss
DrawText:
  ; DrawText works with VDP_TITLESCREEN_PLANE_A exclusively
  move.w  #$0000, -(sp)
  move.w  6 + 2(sp), -(sp)                ; Copy plane addr
  move.w  4 + 2 + 2(sp), -(sp)            ; Copy coordinates
  jsr WriteVDPNametableLocation
  PopStack 6

  move.l  8(sp), a0                       ; Load string address into a0

  move.w  #$0, d0                         ; Clear up d0 so we can write a whole word to VDP

  ; Write ascii value in terms of index
StringLoop:
  move.b  (a0)+, d0                      ; Check if string is null-terminated and break if zero
  tst.b   d0                            ; d0 contains the character which may be printed
  beq.s   StringLoop_End

  subi.b  #$20, d0                      ; Subtract 32 from ascii value (because text is located at top of rom)
  move.w  d0, (VDP_DATA)                ; Write data

  bra.s StringLoop
StringLoop_End:
  rts

 endif
