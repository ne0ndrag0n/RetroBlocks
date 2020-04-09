  ORG $00000000

  include 'constants/system.asm'
  include 'bootstrap/vectors.asm'
  include 'bootstrap/headers.asm'
  include 'bootstrap/init.asm'

  jmp RenderThread

BusError:
  rte

AddressError:
  rte

IllegalInstr:
  rte

TrapException:
  rte

ExternalInterrupt:
  rte

HBlank:
  rte

  ifd TESTSUITE
  include 'testsuite/test_vblank.asm'
  else
  include 'modules/interrupts/vblank.asm'
  endif

  include 'lib/echo.asm'
  include 'modules/mod.asm'
  include 'data/mod.asm'
  include 'constants/en_US.asm'

RomEnd:
  ORG $00020000
  dc.b %11111111
  end 0
