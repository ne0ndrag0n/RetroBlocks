 ifnd H_INTERRUPT_CONSTANTS
H_INTERRUPT_CONSTANTS = 1

  macro DisableInterrupts
    move.w	#$2700,sr		; disable interrupts
  endm

  macro EnableInterrupts
    move.w	#$2000, sr	;re-enable interrupts
  endm

 endif
