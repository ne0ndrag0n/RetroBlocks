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

	move.w	#0, -(sp)	; 6(sp) Tile index of target tile
	move.w	#0, -(sp)	; 4(sp) Palette of target tile
	move.w	#0, -(sp)	; 2(sp) Word containing beginning xx yy coordinate of tile
	move.w	#0, -(sp)	; (sp)  Word containing current iteration

RenderBoard_ExecuteCommand:
	move.l	(a0), d0	; Load an entire rendertable command

	move.b	d0, (sp)	; Number of times we need to "stamp" a 4x4 region, going diagonally x+2 tiles, y+1 tile

	lsr.l	#8, d0
	move.w  d0, 2(sp)	; Origin dimension

	; Get the tile and palette located at the target nametable index
	move.w	2(sp), d1
	VdpGetNametableEntry d1, #VDP_GAMEPLAY_PLANE_B

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
	move.l	sp, d0
	addi.l	#32 + 15, d0
	move.l	d0, sp			; (sp) - palette
							; 15(sp) - tile
							; Local variables begin again at 47

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
	move.w	6(fp), -(sp)
	move.w	4(fp), -(sp)	; Push coordinates for worldgen
	jsr 8(fp)
	PopStack 4

	; TODO: With the worldgen result, fetch the tile that correlates with the 4x4 tile we are currently in
	; Big TODO!

	RestoreFramePointer
	rts

; Get the colour set for two tiles.
; a1 a1 a1 a1 - Address of the first 8x8 tile
; a2 a2 a2 a2 - Address of the second 8x8 tile
; a3 a3 a3 a3 - Address of the first tile's palette
; a4 a4 a4 a4 - Address of the second tile's palette
; a5 a5 a5 a5 - Address of the result
; Returns:	00 bb - 1 if the tile contains 15 elements or under
;                   0 if the tile contains over 15 elements.
;                   Result in a5 a5 a5 a5 is valid only for return value of 1.
GetTileColourSet:
	rts

; Given a colour set, find a palette that it can fit within.
; aa aa aa aa - Address to the colour set.
; Returns: 00 pp - Palette selected if successful (PAL1-PAL3), 0 otherwise
FindPalette:
	rts

	endif