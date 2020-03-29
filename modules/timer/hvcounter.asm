  ifnd H_TIMER_HVCOUNTER
H_TIMER_HVCOUNTER = 1

; Returns: Vcounter value (top 8 bits)
GetVCounter:
  move.w  VDP_CONTROL, d0        ; Check to make sure a vblank isn't active
  btst    #3, d0                 ; If vblank is active...
  bne.s   GetVCounter            ; Try again until it's free (only valid when vblank is clear)

  move.w  VDP_HVCOUNTER, d0      ; Read hv counter and only keep the vcounter
  lsr.w   #7, d0
  lsr.w   #1, d0
  rts

  endif
