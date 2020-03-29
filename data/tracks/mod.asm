  ifnd H_TRACKS_MOD
H_TRACKS_MOD = 1

BgmDoomsday:
  incbin 'data/tracks/doomsday.esf'

SfxBeep:
  ; What format is this??
  dc.b    $EA,$1A,$4A,$00,$2A,$00
  dc.b    $0A,2*36,$FE,4
  dc.b    $FF

  endif
