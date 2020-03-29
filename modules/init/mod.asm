 ifnd H_INIT_MOD
H_INIT_MOD = 1

 include 'modules/init/patterns.asm'
 include 'modules/init/palettes.asm'

InitSubsystems:
  ; TODO: Below, all this stuff gets moved into other modules

  ; Draws the string "bread"
  ;move.l #( String_Bread ), -(sp)
  ;move.w #$0005, -(sp)
  ;jsr DrawText
  ;PopStack 6

  ; This is the bread icon
  ;move.w  #$0020, -(sp)                   ; 0 priority, palette 2, no flips
  ;move.w  #VDP_PLANE_A, -(sp)             ; Draw to plane A
  ;move.w  #$0060, -(sp)                   ; Bread gets loaded at numeric index 0x0060
  ;move.w  #$0605, -(sp)                   ; Bread is a 6x5 tile image
  ;move.w  #$0505, -(sp)                   ; We're moving bread *under* the text now
  ;jsr BlitPattern
  ;PopStack 10
  rts

 endif
