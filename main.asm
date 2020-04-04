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

VBlank:
  ; FIXME: This VBlank handler will skip updating joypad status if a thread needs to be swapped
  ; This may create problems with joypad responsiveness
  include 'modules/helpers/context.asm'
  DisableInterrupts

  jmp ThreaderUpdate

VBlank_Update:
  QuickContextSave
  jsr UpdateTicks
  jsr JoypadVBlank
  QuickContextRestore

VBlank_Finally:
  EnableInterrupts
  rte

  include 'lib/echo.asm'
  include 'modules/mod.asm'
  include 'data/mod.asm'
  include 'constants/en_US.asm'

RomEnd:
  ORG $00020000
  dc.b %11111111
  end 0
