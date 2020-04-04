  ifnd H_HELPERS_CONTEXT
H_HELPERS_CONTEXT = 1

  macro QuickContextSave
    movem.l d0-d7/a0-a6, -(sp)
  endm

  macro QuickContextRestore
    movem.l (sp)+, d0-d7/a0-a6
  endm

  endif
