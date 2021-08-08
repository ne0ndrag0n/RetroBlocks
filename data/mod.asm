  ifnd H_DATA_MOD
H_DATA_MOD = 1


  ORG $00004000
  include 'data/patterns/mod.asm'
  include 'data/palettes/mod.asm'
  include 'data/tables/mod.asm'
  include 'data/models/mod.asm'

  endif
