  ifnd H_INSTRUMENT_MOD
H_INSTRUMENT_MOD = 1

;****************************************************************************
; PointerList
; Pointer list used by Echo
;****************************************************************************

SndPointerList:
    Echo_ListEntry Instr_PSGFlat        ; $00 [PSG] Flat PSG instrument
    Echo_ListEntry Instr_DGuitar        ; $01 [FM] Distortion guitar
    Echo_ListEntry Instr_Snare          ; $02 [PCM] Snare drum
    Echo_ListEntry Instr_Kick           ; $03 [PCM] Bass drum (kick)
    Echo_ListEntry Instr_Strings        ; $04 [FM] String ensemble
    Echo_ListEntry Instr_Bass           ; $05 [FM] Standard bass
    Echo_ListEntry Instr_SoftPSG        ; $06 [PSG] Soft PSG envelope
    Echo_ListEntry Instr_PianoPSG       ; $07 [PSG] Piano PSG instrument
    Echo_ListEntry Instr_MidiPSG        ; $08 [PSG] MIDI square lead
    Echo_ListEntry Instr_MidiPiano      ; $09 [FM] MIDI piano
    Echo_ListEntry Instr_MidiLead1      ; $0A [FM] MIDI square lead
    Echo_ListEntry Instr_MidiLead2      ; $0B [FM] MIDI sawtooth lead
    Echo_ListEntry Instr_MidiFlute      ; $0C [FM] MIDI flute
    Echo_ListEntry Instr_NepelPSG       ; $0D [PSG] Nepel Four PSG instr.
    Echo_ListEntry Instr_MidiSynthBass  ; $0E [FM] MIDI synth bass
    Echo_ListEntry Instr_MidiLead1F     ; $0F [FM] MIDI square (filtered)
    Echo_ListEntry Instr_MidiLead2F     ; $10 [FM] MIDI sawtooth (filtered)
    Echo_ListEntry Instr_Seashore       ; $11 [PSG] Seashore
    Echo_ListEntry Instr_HitHat         ; $12 [PSG] Hit-hat
    Echo_ListEntry Instr_PSGString      ; $13 [PSG] PSG string
    Echo_ListEntry Instr_EGuitar        ; $14 [FM] Electric guitar
    Echo_ListEnd

;****************************************************************************
; Instrument $00 [PSG]
; Flat PSG instrument (no envelope)
;****************************************************************************

Instr_PSGFlat:
    dc.b    $FE,$00,$FF
Instr_PSGFlatEnd:

;****************************************************************************
; Instrument $01 [FM]
; Distortion guitar
;****************************************************************************

Instr_DGuitar:
    incbin  "data/instruments/dguitar.eif"
Instr_DGuitarEnd:

;****************************************************************************
; Instrument $02 [PCM]
; Snare drum
;****************************************************************************

Instr_Snare:
    incbin  "data/instruments/snare.ewf"
Instr_SnareEnd:

;****************************************************************************
; Instrument $03 [PCM]
; Bass drum
;****************************************************************************

Instr_Kick:
    incbin  "data/instruments/kick.ewf"
Instr_KickEnd:

;****************************************************************************
; Instrument $04 [FM]
; String ensemble
;****************************************************************************

Instr_Strings:
    incbin  "data/instruments/string.eif"
Instr_StringsEnd:

;****************************************************************************
; Instrument $05 [FM]
; Standard bass
;****************************************************************************

Instr_Bass:
    incbin  "data/instruments/bass.eif"
Instr_BassEnd:

;****************************************************************************
; Instrument $06 [PSG]
; "Soft" PSG envelope
;****************************************************************************

Instr_SoftPSG:
    dc.b    $00,$01,$01,$02,$02,$02,$03,$03,$03,$03,$FE,$04,$FF
Instr_SoftPSGEnd:

;****************************************************************************
; Instrument $07 [PSG]
; Piano-like PSG instrument
;****************************************************************************

Instr_PianoPSG:
    dc.b    $00,$01,$02,$03,$04,$04,$05,$05
    dc.b    $06,$06,$07,$07,$08,$08,$08,$08
    dc.b    $09,$09,$09,$09,$0A,$0A,$0A,$0A
    dc.b    $0B,$0B,$0B,$0B,$0C,$0C,$0C,$0C
    dc.b    $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D
    dc.b    $0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E
    dc.b    $0E,$0E,$0E,$0E,$FE,$0F,$FF
Instr_PianoPSGEnd:

;****************************************************************************
; Instrument $08 [PSG]
; MIDI square wave instrument (GM81)
;****************************************************************************

Instr_MidiPSG:
    dc.b    $00,$01,$02,$FE,$03,$FF
Instr_MidiPSGEnd:

;****************************************************************************
; Instrument $09 [FM]
; MIDI acoustic piano (GM01)
;****************************************************************************

Instr_MidiPiano:
    incbin  "data/instruments/piano.eif"
Instr_MidiPianoEnd:

;****************************************************************************
; Instrument $0A [FM]
; MIDI square wave instrument (GM81)
;****************************************************************************

Instr_MidiLead1:
    incbin  "data/instruments/square.eif"
Instr_MidiLead1End:

;****************************************************************************
; Instrument $0B [FM]
; MIDI sawtooth wave instrument (GM82)
;****************************************************************************

Instr_MidiLead2:
    incbin  "data/instruments/saw.eif"
Instr_MidiLead2End:

;****************************************************************************
; Instrument $0C [FM]
; MIDI flute instrument (GM74)
;****************************************************************************

Instr_MidiFlute:
    incbin  "data/instruments/flute.eif"
Instr_MidiFluteEnd:

;****************************************************************************
; Instrument $0D [PSG]
; Nepel Four PSG instrument
;****************************************************************************

Instr_NepelPSG:
    dc.b    $05,$06,$FE,$07,$FF
Instr_NepelPSGEnd:

;****************************************************************************
; Instrument $0E [FM]
; MIDI synth bass (GM39)
;****************************************************************************

Instr_MidiSynthBass:
    incbin  "data/instruments/ebass.eif"
Instr_MidiSynthBassEnd:

;****************************************************************************
; Instrument $0F [FM]
; MIDI square wave instrument (GM81) (filtered)
;****************************************************************************

Instr_MidiLead1F:
    incbin  "data/instruments/squaref.eif"
Instr_MidiLead1FEnd:

;****************************************************************************
; Instrument $10 [FM]
; MIDI sawtooth wave instrument (GM82) (filtered)
;****************************************************************************

Instr_MidiLead2F:
    incbin  "data/instruments/sawf.eif"
Instr_MidiLead2FEnd:

;****************************************************************************
; Instrument $11 [PSG]
; Seashore
;****************************************************************************

Instr_Seashore:
    dcb.b   4, $0E
    dcb.b   4, $0D
    dcb.b   4, $0C
    dcb.b   4, $0B
    dcb.b   4, $0A
    dcb.b   4, $09
    dcb.b   4, $08
    dcb.b   4, $07
    dcb.b   4, $06
    dcb.b   60, $05
    dcb.b   4, $06
    dcb.b   4, $07
    dcb.b   4, $08
    dcb.b   4, $09
    dcb.b   4, $0A
    dcb.b   4, $0B
    dcb.b   4, $0C
    dcb.b   4, $0D
    dcb.b   4, $0E
    dc.b    $FE, $0F, $FF
Instr_SeashoreEnd:

;****************************************************************************
; Instrument $12 [PSG]
; Hit-hat
;****************************************************************************

Instr_HitHat:
    dc.b    $00, $01, $02, $04, $06, $08, $0C
    dc.b    $FE, $0F, $FF
Instr_HitHatEnd:

;****************************************************************************
; Instrument $13 [PSG]
; PSG string
;****************************************************************************

Instr_PSGString:
    dcb.b   4, $0E
    dcb.b   4, $0D
    dcb.b   4, $0C
    dcb.b   4, $0B
    dcb.b   4, $0A
    dcb.b   4, $09
    dcb.b   4, $08
    dc.b    $FE, $07, $FF
Instr_PSGStringEnd:

;****************************************************************************
; Instrument $14 [FM]
; Electric guitar
;****************************************************************************

Instr_EGuitar:
    incbin  "data/instruments/eguitar.eif"
Instr_EGuitarEnd:

  endif
