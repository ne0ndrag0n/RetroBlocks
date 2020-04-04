 ifnd H_STATIC_VDP_TEXT
H_STATIC_VDP_TEXT = 1

; Coordinates: xx yy
; String address: ss ss ss ss
DrawText:
  ; DrawText works with VDP_PLANE_A exclusively
  move.w  #$0000, -(sp)
  move.w  #VDP_PLANE_A, -(sp)             ; Push plane addr
  move.w  8(sp), -(sp)                    ; Copy coordinates
  jsr WriteVDPNametableLocation
  move.l  sp, d0
  addi.l  #6, d0
  move.l  d0, sp                          ; Pop coords after writing VDP word

  move.l 6(a7), a0                        ; Load string address into a0

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
