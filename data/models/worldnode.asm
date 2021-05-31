    ifnd H_3DMODEL_NODE
H_3DMODEL_NODE = 1

; Right-handed coordinate system (Z+ out of screen)
; Vertex format (all values are 16.16 data type):
;   position_x, position_y, position_z

ModelWorldNode:
FIXED16_PLUS_HALF =  $00008000     ;  0.5
FIXED16_MINUS_HALF = $FFFF8000     ; -0.5

    ; Front face:
    ;   -0.5, -0.5, 0.5
    ;   -0.5, 0.5, 0.5
    ;   0.5, 0.5, 0.5
    ;   0.5, -0.5, 0.5
    dc.l    FIXED16_MINUS_HALF, FIXED16_MINUS_HALF, FIXED16_PLUS_HALF
    dc.l    FIXED16_MINUS_HALF, FIXED16_PLUS_HALF,  FIXED16_PLUS_HALF
    dc.l    FIXED16_PLUS_HALF,  FIXED16_PLUS_HALF,  FIXED16_PLUS_HALF
    dc.l    FIXED16_PLUS_HALF,  FIXED16_MINUS_HALF, FIXED16_PLUS_HALF

    endif