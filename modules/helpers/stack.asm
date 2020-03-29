 ifnd H_HELPERS_STACK
H_HELPERS_STACK = 1

 macro PopStack
  move.l sp, d1
  addi.l #\1, d1
  move.l d1, sp
 endm

 macro Allocate
  move.l  sp, d1      ; Allocate n bytes for object
  sub.l   \1, d1
  move.l  d1, sp

  move.l  sp, \2      ; Return this as "self"
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
