  ORG $00000000

  include 'constants/system.asm'
  include 'bootstrap/vectors.asm'
  include 'bootstrap/headers.asm'
  include 'bootstrap/init.asm'

  jmp LoadTitlescreen

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

VBlank:
  include 'modules/helpers/context.asm'
  ContextSave
  DisableInterrupts

  ; vblank stuff goes here
VBlank_Threader:
  ; jmp ThreaderUpdate
VBlank_Update:
  jsr UpdateTicks
  jsr JoypadVBlank

VBlank_End:
  EnableInterrupts
  ContextRestore
  rte

  include 'lib/echo.asm'
  include 'modules/mod.asm'
  include 'data/mod.asm'
  include 'constants/en_US.asm'

RomEnd:
  ORG $00020000
  dc.b %11111111
  end 0
