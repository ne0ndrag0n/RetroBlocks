  ifnd H_MATH_LERP
H_MATH_LERP = 1

  macro MathLerp
    move.w  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr Lerp
    PopStack 6
  endm

; p1 p1 - p1
; p2 p2 - p2
; 00 pp - Percent
Lerp:
  ;( p1 * percent ) / 100 + ( p2 * ( 100 - percent ) / 100 )
  move.w  #100, d0        ; 100 - percent
  sub.w   8(sp), d0
  muls.w  6(sp), d0       ; * p2
  divs.w  #100, d0        ; / 100

  move.w  4(sp), d1       ; p1 * percent
  muls.w  8(sp), d1
  divs.w  #100, d1        ; / 100

  add.w   d1, d0
  rts

  endif
