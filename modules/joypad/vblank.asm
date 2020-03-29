 ifnd H_JOYPAD_VBLANK
H_JOYPAD_VBLANK = 1

JoypadVBlank:
  RequestZ80Bus
  jsr WaitForZ80Bus

  move.b  #0, (CTRL_1_DATA)     ; Set multiplexer in controller low to read start, A
  ControllerDelay

  move.b  (CTRL_1_DATA), d0     ; Read controller data (00 SA 00 DU)
  lsl.b   #2, d0                ; Take just the top two bits SA
  andi.b  #$C0, d0

  move.b  #$40, (CTRL_1_DATA)   ; Set multiplexer in controller high to read the rest of the buttons
  ControllerDelay

  move.b  (CTRL_1_DATA), d1     ; xx CB RL DU
  andi.b  #$3F, d1              ; Take just the bottom 6 bits
  or.b    d1, d0                ; OR them onto d0
  not.b   d0                    ; Whole thing comes out fucky so invert it

  move.b  d0, (JOYPAD_STATE_1)  ; Write it to joypad state 1
                                ; SA CB RL DU

  ReturnZ80Bus
  rts

 endif
