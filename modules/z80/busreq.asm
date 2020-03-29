 ifnd H_Z80_BUSREQ
H_Z80_BUSREQ = 1

WaitForZ80Bus:
  btst    #0, Z80_BUS_STATUS
  bne.s   WaitForZ80Bus
  rts

 endif
