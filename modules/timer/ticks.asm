  ifnd H_TIMER_TICKS
H_TIMER_TICKS = 1

TOTAL_TICKS = $FF0012

  macro TimerWaitMs
    move.w  \1, -(sp)
    jsr WaitMs
    PopStack 2
  endm

  macro TimerWaitTicks
    move.l  \1, -(sp)
    jsr WaitTicks
    PopStack 4
  endm

  macro TimerHiResWaitTicks
    move.l  \1, -(sp)
    jsr HiResWaitTicks
    PopStack 4
  endm

; Every second, this value is incremented by 60 ($3C)
UpdateTicks:
  move.l  TOTAL_TICKS, d0
  addi.l  #1, d0
  move.l  d0, TOTAL_TICKS
  rts

; tt tt tt tt - Amount to wait, in ticks
; Use vcounter to get higher-resolution timer wait (13,440 times per second/224 lines per vblank at 60 vblanks a second)
; Slightly inaccurate as vblank may burn many cycles
HiResWaitTicks:
  move.l  d2, -(sp)

  move.l  #0, d0
  move.l  #0, d1          ; d1 is a long that holds the total ticks elapsed
  move.l  #0, d2          ; d2 saves the old raw value

  jsr GetVCounter         ; Save an initial copy of the vcounter
  move.w  d0, d2

HiResWaitTicks_Loop:
  jsr GetVCounter
  cmp.w d2, d0
  beq.s HiResWaitTicks_Loop             ; Nothing even elapsed if it's equal - yes, that can happen.
                                        ; Keep looping until *something* changes.
  bhi.s HiResWaitTicks_DidntLoopAround

HiResWaitTicks_LoopedAround:
  ; If new raw vcounter is less than old raw vcounter, we looped!
  ; ( 224 - old ) + new = value to add to total
  move.w  d0, -(sp)       ; Save value just fetched

  move.w  #224, d0        ; 224 - old
  sub.w   d2, d0
  add.w   (sp), d0        ; + new

  add.l   d0, d1          ; Add that value to total

  move.w  (sp)+, d2       ; Pop value just fetched, right into d2
  bra.s   HiResWaitTicks_SaveAndVerify

HiResWaitTicks_DidntLoopAround:
  ; If new raw vcounter is more than old raw vcounter, we didn't yet loop around.
  ; Subtract old from new and add that amount to d1
  move.w  d0, -(sp)       ; Save value just fetched

  sub.w d2, d0            ; new = new - old
  add.l d0, d1            ; total = total + new

  move.w  (sp)+, d2       ; Pop value just fetched, right into d2

HiResWaitTicks_SaveAndVerify:
  cmp.l   8(sp), d1               ; Verify if d1 is still less than the desired amount of ticks elapsed
  blo.s   HiResWaitTicks_Loop     ; Go there if it is still less

  move.l  (sp)+, d2
  rts

; ss ss - Amount to wait, in milliseconds
; Wait up to 1/60th of a second
WaitMs:
  ; Every 60 ticks, roughly 1000 ms elapses
  ; 60 ticks       1 tick
  ; -------- = -------------
  ; 1000 ms       16.66 ms
  ; All bets are off if you provide a time less than 17 ms
  move.l  #0, d0            ; (ss ss) / 16 = Number of ticks to wait
  move.w  4(sp), d0
  divu.w  #16, d0
  andi.l  #$0000FFFF, d0    ; Keep only the quotient result

  add.l   TOTAL_TICKS, d0   ; Where we eventually need to end up

WaitMs_Loop:
  cmp.l   TOTAL_TICKS, d0   ; TOTAL_TICKS will be incremented by the vblank interrupt
  bgt.s   WaitMs_Loop       ; If d0 still >= TOTAL_TICKS, keep on waitin'
  rts

; tt tt tt tt - Amount to wait, in ticks
WaitTicks:
  move.l  4(sp), d0
  add.l   TOTAL_TICKS, d0

WaitTicks_Loop:
  cmp.l   TOTAL_TICKS, d0
  bgt.s   WaitTicks_Loop
  rts

  endif
