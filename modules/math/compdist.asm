  ifnd H_MATH_COMPDIST
H_MATH_COMPDIST = 1

  macro MathGetComparisonDistance
    move.w  \4, -(sp)
    move.w  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr GetComparisonDistance
    PopStack 8
  endm

; x1 x1
; y1 y1
; x2 x2
; y2 y2
; Returns: s16 distance value to be used for comparison only
GetComparisonDistance:
  SetupFramePointer

  ; (x2-x1)^2 + (y2-y1)^2
  move.w  8(fp), d0     ; x2 - x1
  sub.w   4(fp), d0

  muls.w  d0, d0        ; ^2

  move.w  10(fp), d1    ; y2 - y1
  sub.w   6(fp), d1

  muls.w  d1, d1        ; ^2

  add.w   d1, d0        ; (x2-x1)^2 + (y2-y1)^2

  RestoreFramePointer
  rts


  endif
