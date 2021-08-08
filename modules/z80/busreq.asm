 ifnd H_Z80_BUSREQ
H_Z80_BUSREQ = 1

WaitForZ80Bus:
  cmpi.w  #$0100, (Z80_BUS_REQUEST)
  bne.s   WaitForZ80Bus
  rts

 endif
