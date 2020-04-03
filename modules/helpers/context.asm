  ifnd H_HELPERS_CONTEXT
H_HELPERS_CONTEXT = 1

  macro ContextSave
    movem.l d0-d7/a0-a6, -(sp)
    move.w  sr, -(sp)
  endm

  macro ContextRestore
    move.w  (sp)+, sr
    movem.l (sp)+, d0-d7/a0-a6
  endm

  endif
