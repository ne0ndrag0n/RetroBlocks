 ifnd H_HELPERS_STACK
H_HELPERS_STACK = 1

 macro PopStack
  move.l sp, d1
  addi.l #\1, d1
  move.l d1, sp
 endm

 macro Allocate
 if NARG == 2
  move.l  sp, \2
  sub.l   \1, \2
  move.l  \2, sp
 else
  move.l  sp, d1      ; Allocate n bytes for object
  sub.l   \1, d1
  move.l  d1, sp
 endif
 endm

 macro Deallocate
  move.l  sp, d1
  add.l   \1, d1
  move.l  d1, sp
 endm

 macro SetupFramePointer
  move.l  fp, -(sp)

  move.l  sp, d1
  addi.l  #4, d1
  move.l  d1, fp
 endm

 macro RestoreFramePointer
  move.l  (sp)+, fp
 endm

 endif
