	ifnd H_INTERRUPTS_VBLANK
H_INTERRUPTS_VBLANK = 1

  include 'modules/helpers/context.asm'

VBlank:
  jmp ThreaderSaveContext

VBlank_Begin:
  jmp ThreaderUpdate

VBlank_Update:
  jsr UpdateTicks
  jsr JoypadVBlank
  jsr DmaQueueExecute

  jmp ThreaderLoadContext

VBlank_End:
  rte

	endif