 ifnd H_INTERRUPT_CONSTANTS
H_INTERRUPT_CONSTANTS = 1

  macro DisableInterrupts
    ori.w   #$0700, sr	; disable interrupts
  endm

  macro EnableInterrupts
    andi.w	#$F8FF, sr	; re-enable interrupts
  endm

 endif
