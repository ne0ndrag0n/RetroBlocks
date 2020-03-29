 ifnd H_Z80_CONSTANTS
H_Z80_CONSTANTS = 1

  macro RequestZ80Bus
     move.w #$0100, (Z80_BUS)
  endm

  macro ResetZ80
     move.w #$0100, (Z80_RESET)
  endm

  macro ReturnZ80Bus
     move.w	#0, (Z80_BUS)
  endm

Z80_ADDRESS_SPACE=$00A10000
Z80_BUS=$00A11100
Z80_BUS_STATUS=$00A11101
Z80_RESET=$00A11200

 endif
