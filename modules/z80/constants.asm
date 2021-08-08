 ifnd H_Z80_CONSTANTS
H_Z80_CONSTANTS = 1

Z80_RAM         = $A00000
Z80_BUS_REQUEST = $A11100
Z80_RESET =       $A11200

  macro PauseZ80
   move.w   #$0100, (Z80_BUS_REQUEST)
  endm

  macro RequestZ80Bus
     PauseZ80
     jsr WaitForZ80Bus
  endm

  macro ReturnZ80Bus
     move.w	#$0000, (Z80_BUS_REQUEST)
  endm

  macro RequestZ80Reset
     move.w #$0000, (Z80_RESET)
  endm

  macro ReturnZ80Reset
     move.w #$0100, (Z80_RESET)
  endm

 endif
