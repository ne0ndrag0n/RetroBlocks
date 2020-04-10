	ifnd H_WORLDGEN
H_WORLDGEN = 1

;
; Concordia worldgen functions
; (All worlds are 255x255x255)
;
; A worldgen function has an interface of:
; Block worldgenGetBlock( u8 x, u8 y, u8 z );
; Where "Block" is a u16 containing one status u8 and one enumated u8 block type.

	macro WorldgenGetBlock
		move.l	\3, -(sp)
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		jsr GetBlock
		PopStack 8
	endm

; Wrap a worldgen by searching for a diff before calling the substitution for the given coordinate.
; xx yy - Coordinates
; 00 zz
; aa aa aa aa - Worldgen address
; Returns: dd dd - Desired block and its status
GetBlock:
	; Boundary check coordinates - Must fit within boundary
	cmpi.b	#-(WORLD_BOUNDARY >> 1), 4(sp)
	blt.s	GetBlock_ReturnAir

	cmpi.b	#(WORLD_BOUNDARY >> 1), 4(sp)
	bgt.s	GetBlock_ReturnAir

	cmpi.b	#-(WORLD_BOUNDARY >> 1), 5(sp)
	blt.s	GetBlock_ReturnAir

	cmpi.b	#(WORLD_BOUNDARY >> 1), 5(sp)
	bgt.s	GetBlock_ReturnAir

	cmpi.b	#-(WORLD_BOUNDARY >> 1), 7(sp)
	blt.s	GetBlock_ReturnAir

	cmpi.b	#(WORLD_BOUNDARY >> 1), 7(sp)
	bgt.s	GetBlock_ReturnAir

	; TODO check FindDiff here

GetBlock_ReturnWorldgen:
	; If we get here, there's no difference in this position from a natural world state
	move.w	6(sp), -(sp)
	move.w	4(sp), -(sp)
	jsr		8(sp)
	PopStack 4
	rts
GetBlock_ReturnAir:
	move.w	#0, d0
	rts

; Search SRAM for a diff at this location.
; xx yy
; 00 zz
; Returns: 00 dd dd cc
;          cc - Status (0 for no result, 1 for result)
;          dd dd - If Status is 1, dd dd contains the substitution for this location.
FindDiff:
	; TODO - use SramContainsDiff on the coordinate to see if an instruction impacts it
	; If it does...use additional methods to determine what block that is exactly.
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


; This is an even simpler worldgen than "flat".
; Grass from z=-127 to z=0
; Air from z=1 to z=128
;
; xx yy
; 00 zz
; Returns: dd dd - Desired block and its status
WorldgenTest:
	cmpi.b	#0, 7(sp)
	ble.s	WorldgenTest_ReturnDirt

WorldgenTest_ReturnAir:
	move.w	#BLOCK_AIR, d0
	rts

WorldgenTest_ReturnDirt:
	move.w	#( BLOCK_DIRT_BARREN | BLOCK_DIRT ), d0
	rts


	endif