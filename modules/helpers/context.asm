  ifnd H_HELPERS_CONTEXT
H_HELPERS_CONTEXT = 1

  macro ContextSave
    move.l  d0, -(sp)
    move.l  d1, -(sp)
    move.l  a0, -(sp)
    move.l  a1, -(sp)
  endm

  macro ContextRestore
    move.l  (sp)+, a1
    move.l  (sp)+, a0
    move.l  (sp)+, d1
    move.l  (sp)+, d0
  endm

  endif
