 ifnd H_INTERRUPT_CONSTANTS
H_INTERRUPT_CONSTANTS = 1

LOCK_STATUS = $FF000F
LOCK_VDP_CONTROL = $01

  macro DisableInterrupts
    ori.w   #$0700, sr	; disable interrupts
  endm

  macro EnableInterrupts
    andi.w	#$F8FF, sr	; re-enable interrupts
  endm

  macro TakeVdpControlLock
    ori.b #LOCK_VDP_CONTROL, LOCK_STATUS
  endm

  macro ReleaseVdpControlLock
    andi.b #(~LOCK_VDP_CONTROL), LOCK_STATUS
  endm

 endif
