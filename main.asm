  ORG $00000000

  include 'constants/system.asm'
  include 'bootstrap/vectors.asm'
  include 'bootstrap/headers.asm'
  include 'bootstrap/init.asm'

  jmp MainLoop

BusError:
  rte

AddressError:
  move.w  #$ADD7, d0
  bra.s AddressError

IllegalInstr:
  rte

TrapException:
  rte

UserError:
  move.w  #$DEAD, d0
  bra.s UserError

ExternalInterrupt:
  rte

  include 'modules/interrupts/vblank.asm'

  include 'modules/mod.asm'
  include 'data/mod.asm'
  include 'constants/en_US.asm'

RomEnd:
  ORG $00070000
  dc.b %11111111
  end 0
