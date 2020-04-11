	ifnd H_INTERRUPTS_VBLANK
H_INTERRUPTS_VBLANK = 1

  include 'modules/helpers/context.asm'

VBlank:
  ; FIXME: This VBlank handler will skip updating joypad status if a thread needs to be swapped
  ; This may create problems with joypad responsiveness
  jmp ThreaderUpdate

VBlank_Update:
  QuickContextSave
  jsr UpdateTicks
  jsr JoypadVBlank
  QuickContextRestore

VBlank_Finally:
  rte

	endif