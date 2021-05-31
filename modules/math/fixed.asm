    ifnd H_FIXED_16_16
H_FIXED_16_16 = 1

; aa aa aa aa
; bb bb bb bb
; Returns: rr rr rr rr
;          Result of a * b in 16.16. format
FixedMul:
    rts

; aa aa aa aa
; bb bb bb bb
; Returns: rr rr rr rr
;          Result of a / b in 16.16. format
FixedDiv:
    rts

FixedLerp:
    rts

    endif