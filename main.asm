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

  move.b  $FF0000, d0         ; Test if vblank is in progress
  tst.b   d0
  bne.s   EndVBlank           ; Nonzero means we're already doing a vblank - stop, get out!

  ori.b  #$01, d0             ; Overlay a 1 onto the interrupt status
  move.b d0, $FF0000

  ; vblank stuff goes here
  jsr UpdateTicks
  jsr JoypadVBlank

  move.b  $FF0000, d0         ; Unset status bit
  andi.b  #$FE, d0
  move.b  d0, $FF0000

EndVBlank:
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
