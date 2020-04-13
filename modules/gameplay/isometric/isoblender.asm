	ifnd H_GAMEPLAY_ISOMETRIC_ISOBLENDER
H_GAMEPLAY_ISOMETRIC_ISOBLENDER = 1

; Instructions for overlaying tiles:
; * Take the union of the two colour sets across the two tiles due to be merged.
;	* If the number of colours is greater than 15, drop the tile.
;	* Find a palette that can comfortably fit the result palette.
;   * Otherwise, find the nearest fit with enough free space for the new AND existing entries together.
;		* If the missing entries fit into the tile's current palette, add them.
;		* If they don't, add all of the new tile's colour set to the next available palette. (inefficent)
;			* This is the significant challenge that will lead to more dropped tiles. There needs to be
;			  some form of colour rebalancing that can optimally pack all colour sets.
;
;			  (We'd start with iterating through all tiles and assembling color sets from each tile.
;              There may be some set logic operations that can help with finding the optimal palettes.
;              Fit the smaller sets into the larger ones?)
;		* If the above step could not locate a palette with enough free space, drop the tile.
; * If the former tile exists in multiple nametable entries, copy the tile and create a new one in VRAM.
; * Make the required palette substitutions on both the top tile and the bottom tile.
; * Overlay the top tile over the bottom tile, leaving out "0" nibbles in the top tile.


	macro IsoblenderRenderBoard
		move.l	\3, -(sp)
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		jsr RenderBoard
		PopStack 8
	endm

	macro IsoblenderGetRomTileAddress
		move.w	\1, -(sp)
		bsr GetRomTileAddress
		PopStack 2
	endm

; Render the board to the VRAM nametables + patterns, given the world origin point.
; The world will be rendered in a rectangular cutout beginning at the top right.
; xx yy	- Coordinates
; 00 zz - Coordinates
; ww ww ww ww - Worldgen
RenderBoard:
	SetupFramePointer

	; Using the rendertable, iterate each isometric block position
	; When iterating the third byte, move two 8x8 blocks over and one down each time.
	; Call BlendTile to overlay the top tile onto the bottom one.
	; And of course, use the selected worldgen.

	; Allocate necessary local variables
	Allocate #32																; 236(sp) Copy of destination VRAM tile
	Allocate #96																; 140(sp) Sorted CRAM palettes to aid in finding colour sets
	Allocate #96																; 44(sp) Full dump of 3 CRAM palettes - Generate per tile in stamper and DMA when finished
	Allocate #32																; 12(sp) Palette generated from combining ROM tile with target tile
	move.w	#0, -(sp)															; 10(sp) Reserved for temps
	move.l	#IsometricRendertable, -(sp)										; 6(sp) Pointer to current stamper instruction in ROM
	move.w	#( (IsometricRendertable_End - IsometricRendertable) / 4 ), -(sp)	; 4(sp) Number of stamper iterations remaining
	move.w	#0, -(sp)															; 2(sp) Current xx yy position of stamper on plane
	move.w	#0, -(sp)															; (sp)  Word containing current iteration of stamper

	; Dump shared palettes - they will be modified as we go and thrown over the wall to the DMA queue.
	VdpCopyPalette VDP_PAL_1, 44(sp)
	VdpCopyPalette VDP_PAL_2, 76(sp)
	VdpCopyPalette VDP_PAL_3, 108(sp)

RenderBoard_StamperIteration:
	tst.w	4(sp)		; If there's no more stamper instructions, break loop
	beq.s 	RenderBoard_Finally

	subi.w	#1, 4(sp)	; Decrement remaining stamper instructions

	move.l	6(sp), a0	; Load stamper pointer
	move.l	(a0)+, d0	; Format the current rendertable command out into the local variables
						; Also postincrement to next position
	move.b	d0, (sp)	; Number of times we need to "stamp" a 4x4 region, going diagonally x+2 tiles, y+1 tile

	lsr.l	#8, d0
	move.w  d0, 2(sp)	; Stamper position

	move.l	a0, 6(sp)	; Save pointer for next iteration

RenderBoard_ExecuteStamper:
	tst.w	(sp)
	beq.s	RenderBoard_StamperIteration	; Next stamper command if 0
	subi.w	#1, (sp)						; Decrement remaining stamps on this origin

	; Call worldgen and get the block ID we need, then get that block out of the isoblock table
	WorldgenGetBlock 4(fp), 6(fp), 8(fp)
	IsoblenderGetRomTileAddress d0

	bra.s RenderBoard_ExecuteStamper

RenderBoard_Finally:
	PopStack 32 + 96 + 96 + 32 + 12
	RestoreFramePointer
	rts

; Given a block ID and status, return the address to a 4x4 set of tiles.
; ss bb - Status and block ID
; Returns: aa aa aa aa - Address to first tile in a 4x4 set of tiles
;                        Null pointer if this operation could not complete successfully
GetRomTileAddress:
	move.l	#IsoTiles, d0		; Get pointer to IsoTiles table...
	move.b	5(sp), d1
	andi.w	#$00FF, d1
	mulu.w	#4, d1
	add.l	d1, d0				; Add 4n to the base index where n is the block ID

	move.l	d0, a0
	move.l	(a0), a0			; Once we get the address in the IsoTiles table, get the pointer at that address
	move.b	1(a0), d1
	andi.w	#$00FF, d1 			; Save the number of different tile states stored at this ROM location

	add.l	#ISOTILES_HEADER_SIZE, a0 ; Now that the header isn't needed anymore, skip to the tiledata

	move.w	4(sp), d0
	lsr.w	#8, d0
	move.w	d0, 4(sp)			; Now local variable contains only the block status, as the ID is no longer needed

GetRomTileAddress_FindTiledata:
	move.w	(a0)+, d0
	cmp.w	4(sp), d0			; Compare this status flag to the local status flag
	beq.s	GetRomTileAddress_TileFound	; Iterate again if they don't match

	add.l	#512, a0			; One 4x4 tile block runs a total of 512 bytes (8*4 (32) for one block, times 4*4 (16) tiles)
	dbeq	d1, GetRomTileAddress_FindTiledata

	; Tile wasn't found
	move.l	#0, d0				; Return null pointer
	bra.s	GetRomTileAddress_Finally

GetRomTileAddress_TileFound:
	move.l	a0, d0				; Recall that d0 holds the return address

GetRomTileAddress_Finally:
	rts


	endif