	ifnd H_WORLDGEN
H_WORLDGEN = 1

;
; Concordia worldgen functions
; (All worlds are 255x255x255)
;
; A worldgen function has an interface of:
; Block worldgenGetBlock( u8 x, u8 y, u8 z );
; Where "Block" is a u16 containing one status u8 and one enumated u8 block type.


; Determine if the first x, y, z falls within the same chunk as the second x, y, z.
	macro IsSameChunk
		; TODO
	endm

; Search SRAM for a diff at this location.
; xx yy
; 00 zz
; Returns: 00 dd dd cc
;          cc - Status (0 for no result, 1 for result)
;          dd dd - If Status is 1, dd dd contains the substitution for this location.
FindDiff:
	; TODO
	rts

; This is a test worldgen. The "flat" worldgen will create a world with the following characteristics:
; * Bedrock from z=0 to z=2
; * Stone from z=3 to z=10
; * Grass from z=11 to z=15
; * Air from z=16 to z=255
;
; xx yy
; 00 zz
; Returns: dd dd - Desired block and its status
WorldgenFlat:
	cmpi.b	#2, 7(sp)
	ble.s	WorldgenFlat_Bedrock

	cmpi.b  #10, 7(sp)
	ble.s	WorldgenFlat_Stone

	cmpi.b 	#15, 7(sp)
	ble.s	WorldgenFlat_Dirt

WorldgenFlat_Air:
	move.w	#BLOCK_AIR, d0
	rts

WorldgenFlat_Bedrock:
	move.w	#BLOCK_BEDROCK, d0
	rts

WorldgenFlat_Stone:
	move.w	#BLOCK_STONE, d0
	rts

WorldgenFlat_Dirt:
	move.w	#( BLOCK_DIRT_BARREN | BLOCK_DIRT ), d0
	rts


	endif