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

	move.l	#IsometricRendertable, a0											; Load pointer to rendertable
	move.w	#( (IsometricRendertable_End - IsometricRendertable) / 4 ), d1		; Load number of iterations to d1

	; Allocate necessary local variables
	move.l	#0, -(sp)	; 12(sp) ROM address of tileset palette
	move.l	#0, -(sp)	; 8(sp) ROM address of 4x4 tileset
	move.w	#0, -(sp)	; 6(sp) Tile index of target tile
	move.w	#0, -(sp)	; 4(sp) Palette index of target tile
	move.w	#0, -(sp)	; 2(sp) Current xx yy position of stamper on plane
	move.w	#0, -(sp)	; (sp)  Word containing current iteration

RenderBoard_ExecuteCommand:
	; Format the current rendertable command out into the local variables
	move.l	(a0), d0	; Load an entire rendertable command

	move.b	d0, (sp)	; Number of times we need to "stamp" a 4x4 region, going diagonally x+2 tiles, y+1 tile

	lsr.l	#8, d0
	move.w  d0, 2(sp)	; Stamper position

	; Get the tile and palette located at the target nametable index
	move.w	2(sp), d1
	VdpGetNametableEntry d1, #VDP_GAMEPLAY_PLANE_A

	move.w	d0, d1
	andi.w	#$07FF, d1		; Copy to d1 and take only the tile ID
	move.w	d1, 6(sp)		; Store the tile ID

	move.w	d0, d1
	andi.w	#$6000, d1		; Copy to d1 and take only the palette ID
	lsr.w	#7, d1
	lsr.w	#6, d1			; Shift palette over
	mulu.w	#$20, d1		; Each palette is 32 bytes, multiply by 32 bytes to get CRAM index
	move.w	d1,	4(sp)		; Store the palette ID

	; Allocate space for an 8x8 copy of the target tile and its accompanying palette
	Allocate #64, d0		; (sp) - palette
							; 32(sp) - tile

	; Copy palette to (sp)
	move.w	64+4(sp), d0
	move.l	sp, a1
	VdpCopyPalette	d0, a1

	; Then copy target tile to 16(sp)
	move.w	64+6(sp), d0
	move.l	sp, d1
	addi.l	#32, d1
	move.l	d1, a1
	VdpCopyVramTile d0, a1

	; The call to the worldgen method should account for the diffs
	WorldgenGetBlock 4(fp), 6(fp), 8(fp)

	; TODO: With the worldgen result, fetch the tile that correlates with the 4x4 tile we are currently in
	; Big TODO!

	PopStack 64 + 16	; Pop palette, tile, and local variables
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

	; d0 now points to the 122 byte header
	move.l	d0, a0
	move.b	1(a0), d1
	andi.w	#$00FF, d1 			; Save the number of different tile states stored at this ROM location

	addi.l	#ISOTILES_HEADER_SIZE, d0
	move.l	d0, a0				; Now that the header isn't needed anymore, skip to the tiledata

	move.w	4(sp), d0
	lsr.w	#8, d0
	move.w	d0, 4(sp)			; Now local variable contains only the block status, as the ID is no longer needed

GetRomTileAddress_FindTiledata:
	move.w	(a0), d0
	cmp.w	4(sp), d0			; Compare this status flag to the local status flag
	beq.s	GetRomTileAddress_TileFound	; Iterate again if they don't match

	add.l	#514, a0			; One 4x4 tile block runs a total of 514 bytes (8*4 (32) for one block, times 4*4 (16) tiles, plus the status flag)
	dbra	d1, GetRomTileAddress_FindTiledata

	; Tile wasn't found
	move.l	#0, d0				; Return null pointer
	bra.s	GetRomTileAddress_Finally

GetRomTileAddress_TileFound:
	add.l	#2, a0				; adda on the address register to skip past the status flag and get to the desired tiledata
	move.l	a0, d0				; Recall that d0 holds the return address

GetRomTileAddress_Finally:
	rts

; Get the colour set for two tiles.
; a1 a1 a1 a1 - Address of the destination 8x8 tile
; a2 a2 a2 a2 - Address of the destination tile's palette
; a3 a3 a3 a3 - Address of the ROM tile's palette
; a4 a4 a4 a4 - Address of the result
; Returns:	00 bb - 1 if the tile contains 15 elements or under
;                   0 if the tile contains over 15 elements.
;                   Result in a4 a4 a4 a4 is valid only for return value of 1.
GetTileColourSet:
	rts

; Given a colour set, find a palette that it can fit within.
; aa aa aa aa - Address to the colour set.
; Returns: 00 pp - Palette selected if successful (PAL1-PAL3), 0 otherwise
FindPalette:
	rts

	endif