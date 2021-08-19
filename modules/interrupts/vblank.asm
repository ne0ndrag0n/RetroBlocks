	ifnd H_INTERRUPTS_VBLANK
H_INTERRUPTS_VBLANK = 1

  include 'modules/helpers/context.asm'
  include 'modules/timer/ticks.asm'

VBlank:
  QuickContextSave

  UpdateTicks
  jsr JoypadVBlank
  jsr DmaQueueExecute
  jsr HiColorFrameSync

  QuickContextRestore
  rte

	endif