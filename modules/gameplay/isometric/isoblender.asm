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
	move.l	#( (IsometricRendertable_End - IsometricRendertable) / 4 ), d1		; Load number of iterations to d1

	move.w	#0, -(sp)	; 2(sp) Word containing beginning xx yy coordinate of tile
	move.w	#0, -(sp)	; (sp)  Word containing current iteration

RenderBoard_Loop:
	move.l	(a0), d0	; Load an entire rendertable command

	move.b	d0, (sp)	; Number of iterations

	lsr.l	#8, d0
	move.w  d0, 2(sp)	; Origin dimension

RenderBoard_DiagonalLoop:
	; The call to the worldgen method should account for the diffs
	move.w	6(fp), -(sp)
	move.w	4(fp), -(sp)	; Push coordinates for worldgen
	jsr 8(sp)
	PopStack 4

	tst.b	d0				; Nothing to do for air block
	beq.s	RenderBoard_DiagonalLoop_Finally

	; Allocate space for an 8x8 copy of the target tile and its accompanying palette
	move.l	sp, d0
	addi.l	#32 + 15, d0
	move.l	d0, sp			; (sp) - palette
							; 15(sp) - tile

	; Get copy of 8x8 tile out of VRAM
	; TODO

RenderBoard_DiagonalLoop_Finally:

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