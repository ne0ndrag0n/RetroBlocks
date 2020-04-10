	ifnd H_GAMEPLAY_ISOMETRIC_ISOBLENDER
H_GAMEPLAY_ISOMETRIC_ISOBLENDER = 1

; Instructions for overlaying tiles:
; * Take the union of the two colour sets across the two tiles due to be merged.
;	* If the number of colours is greater than 15, drop the tile.
;   * If the tile's colour set fits cleanly into its existing palette, keep it.
;   * If the tile's colour set fits cleanly into another palette, select that palette.
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

; End of a colour set is denoted by encountering 00 00 colour, or 15 elements.

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
	move.w	#0, -(sp)	; 6(sp) Tile index of target tile
	move.w	#0, -(sp)	; 4(sp) Palette of target tile
	move.w	#0, -(sp)	; 2(sp) Word containing beginning xx yy coordinate of tile
	move.w	#0, -(sp)	; (sp)  Word containing current iteration

RenderBoard_ExecuteCommand:
	; Format the current rendertable command out into the local variables
	move.l	(a0), d0	; Load an entire rendertable command

	move.b	d0, (sp)	; Number of times we need to "stamp" a 4x4 region, going diagonally x+2 tiles, y+1 tile

	lsr.l	#8, d0
	move.w  d0, 2(sp)	; Origin dimension

	; Get the tile and palette located at the target nametable index
	move.w	2(sp), d1
	DebugPrintLabelHere
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
	Allocate #47, d0		; (sp) - palette
							; 15(sp) - tile

	; Copy palette to (sp)
	move.w	47+4(sp), d0
	move.l	sp, a1
	VdpCopyPalette	d0, a1

	; Then copy target tile to 15(sp)
	move.w	47+6(sp), d0
	move.l	sp, d1
	addi.l	#15, d1
	move.l	d1, a1
	VdpCopyVramTile d0, a1

	; The call to the worldgen method should account for the diffs
	WorldgenGetBlock 4(fp), 6(fp), 8(fp)

	; TODO: With the worldgen result, fetch the tile that correlates with the 4x4 tile we are currently in
	; Big TODO!

	PopStack 47 + 8	; Pop palette, tile, and local variables
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
	move.l	a2, -(sp)
	move.l	a3, -(sp)
	move.l	a4, -(sp)
	move.l	d2, -(sp)
	move.l	d3, -(sp)

	; The result palette must at LEAST contain the elements from the ROM palette (no extraneous colours are used in ROM)
	; Copy those, then add any colours occuring in the destination tile.
	move.l 12(sp), a0	; a0 = ROM tile palette
	move.l 16(sp), a1	; a1 = Result palette

	move.l	a0, a2
	add.l	#32, a2		; The pointer 32 elements down from the ROM is a boundary condition

	move.l	a1, a3
	add.l	#32, a3     ; Same for result boundary condition
GetTileColourSet_CopyColours:
	cmp.l	a2, a0
	bhs.s	GetTileColourSet_CopyColours_End  ; If we ran through a full palette in the ROM, jump out as there is nothing more to do

	tst.w	(a0)
	beq.s	GetTileColourSet_CopyColours_End  ; If there's a zero colour, break out of the loop

	move.w	(a0)+, (a1)+					  ; Add the word at a0 to a1 and increment both by a word
	bra.s	GetTileColourSet_CopyColours

GetTileColourSet_CopyColours_End:

	; Now, explore the destination 8x8 tile. For each nibble, check it against its native palette and see if the item is already in the new palette.
	; If it's not, add it to the result palette (if there is room). a1 shall either point to next available element or beyond the boundary.
	move.l	4(sp), a0	; a0 = Destination tile

	move.l	a0, a2
	add.l	#32, a2		; The pointer 32 elements down is past the tile

	move.b	#8, d1		; d1 = Number of longwords we need to process

GetTileColourSet_ProcessTile:
	move.b	#8, d2		; d2 = Number of times we repeat the nibble extraction
	move.l	(a0), d0

GetTileColourSet_ProcessTileLongword:
	move.l	d0, d3
	andi.l	#$0000000F, d3		; Move d0 into d3 and take the nibble only
	lsr.l	#4, d0				; Rotate d0 for the next nibble
								; d3 = colour index

	; Get this colour out of the destination palette, and see if it is present in the generated colour set.
	move.l	8(sp), a4			; Grab pointer to destination palette
	lsl.w	#1, d3				; Array of words, so multiply index by 2
	move.w	(a4, d3), d3		; Ooh, indexed addressing!
								; d3 = colour word corresponding to this nibble

	move.l	d3, -(sp)
	VdpFindPaletteEntry	d3, 16+4(sp)								; Find this entry in the result array
	move.l	(sp)+, d3

	cmpi.b	#-1, d0
	bne.s	GetTileColourSet_ProcessTileLongword_Next				; Add a new entry if it is not in the result array

GetTileColourSet_ProcessTileLongword_AddNewEntry:
	cmp.l	a3, a1
	bhs.s	GetTileColourSet_ColoursExceeded

	move.w	d3, (a1)+			; Add the entry to the result colour table

GetTileColourSet_ProcessTileLongword_Next:
	dbra	d2, GetTileColourSet_ProcessTileLongword

	add.l	#4, a0				; Increment the tile longword pointer
	dbra	d1, GetTileColourSet_ProcessTile

	; If we make it here, we have successfully merged the palettes of the ROM tile and the destination tile
	move.w	#1, d0
	bra.s	GetTileColourSet_Finally

GetTileColourSet_ColoursExceeded:
	move.w	#0, d0

GetTileColourSet_Finally:
	move.l	(sp)+, d3
	move.l	(sp)+, d2
	move.l	(sp)+, a4
	move.l	(sp)+, a3
	move.l	(sp)+, a2
	rts

; Given a colour set, find a palette that it can fit within.
; aa aa aa aa - Address to the colour set.
; Returns: 00 pp - Palette selected if successful (PAL1-PAL3), 0 otherwise
FindPalette:
	rts

	endif