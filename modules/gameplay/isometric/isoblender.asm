	ifnd H_GAMEPLAY_ISOMETRIC_ISOBLENDER
H_GAMEPLAY_ISOMETRIC_ISOBLENDER = 1


; Distributing colours across the three usermode palettes is a bin packing problem which is np-hard
;1. Copy palette of tile from ROM
;2. Determine if this palette fully fits into the target tile's palette.
;   If it does, go to step 3
;   If it does not, go to step 6
;3. In the tile from ROM, update nibbles to correspond with their colours in the target tile's palette.
;4. OR the resulting tile over the existing tile
;5. Grab new tile + palette struct from ROM and go back to 1
;
;6. Attempt to insert new colours into the target tile's existing palette.
;    If they fit, go to step 3.
;    If they don't fit, go to step 7
;7. Attempt to find another palette that fully fits this new tile's palette. This will require bringing in colours from the existing tile.
;    If one is found, update the nametable entry to point to this palette, and go to step 3.
;    If one is not found, go to step 8.
;8. Attempt to insert new colours into palette that both shares the most existing colours with the new tile's palette,
;and also has enough room for the new colours.
;    If this can be done, update the nametable entry to point to this palette, and go to step 3.
;    If this cannot be done, go to step 9.
;9. Begin dropping colours from the tile in order to reduce the load it places on the palettes.
;    Take the colour that occurs the least in this palette (e.g. a single blue pixel for water in the corner) and change
;    occurrences of it to transparency (0). Then, drop the colour from the colour set required for the new tile.
;
;    Repeat the process from step 2.

	macro IsoblenderRenderBoard
		move.l	\3, -(sp)
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		jsr RenderBoard
		PopStack 8
	endm

	macro IsoblenderGetRomBlockAddress
		move.w	\1, -(sp)
		bsr GetRomBlockAddress
		PopStack 2
	endm

	macro IsoblenderPaletteContainsSet
		move.l	\2, -(sp)
		move.l	\1, -(sp)
		bsr	PaletteContainsSet
		PopStack 8
	endm

	macro IsoblenderGetTileNibble
		move.l	\2, -(sp)
		move.w	\1, -(sp)
		bsr GetTileNibble
		PopStack 6
	endm

	macro IsoblenderSetTileNibble
		move.l	\3, -(sp)
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		bsr SetTileNibble
		PopStack 8
	endm

	macro IsoblenderStampBlock
		move.l	\3, -(sp)
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		bsr	StampBlock
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

	; Allocate necessary local variables
	move.w	#0, -(sp)															; 106(sp) Copy of coordinates used for iteration
	Allocate #96																; 10(sp) Full dump of 3 CRAM palettes - Generate per tile in stamper and DMA when finished
	move.l	#IsometricRendertable, -(sp)										; 6(sp) Pointer to current stamper instruction in ROM
	move.w	#( (IsometricRendertable_End - IsometricRendertable) / 4 ), -(sp)	; 4(sp) Number of stamper iterations remaining
	move.w	#0, -(sp)															; 2(sp) Current xx yy position of stamper on plane
	move.w	#0, -(sp)															; (sp)  Word containing current iteration of stamper

	; Dump shared palettes - they will be modified as we go and thrown over the wall to the DMA queue.
	VdpCopyPalette VDP_PAL_1, 10(sp)
	VdpCopyPalette VDP_PAL_2, 42(sp)
	VdpCopyPalette VDP_PAL_3, 74(sp)

	move.w	4(fp), 106(sp)			; Copy xx yy of world origin to start off the stamper

RenderBoard_StamperIteration:
	tst.w	4(sp)		; If there's no more stamper instructions, break loop
	beq.w 	RenderBoard_Finally

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
	beq.s	RenderBoard_NextStamperIteration	; Next stamper command if 0

	; Call worldgen and get the block ID we need, then get that block out of the isoblock table
	WorldgenGetBlock 4(fp), 6(fp), 8(fp)

	move.w	2(sp), d1			; Prepare first argument

	move.l	sp, a0
	add.l	#10, a0				; Prepare third argument

	IsoblenderStampBlock d1, d0, a0

	addi.b	#2, 2(sp)			; VDP plane position x+2
	addi.b	#1, 3(sp)			; VDP plane position y+1

	subi.b	#1, 107(sp)			; Move -1 along the world in the y dimension

	subi.w	#1, (sp)			; Decrement remaining stamps on this origin

	bra.s	RenderBoard_ExecuteStamper

RenderBoard_NextStamperIteration:
	subi.b	#1, 4(fp)			; origin x-1
	addi.b	#1, 5(fp)			; origin y+1
	move.w	4(fp), 106(sp)		; Set up iteration counter for next iteration of stamper

	bra.s	RenderBoard_StamperIteration

RenderBoard_Finally:
	PopStack 96 + 12
	RestoreFramePointer
	rts

; Stamp a 4x4 block (16 tiles total) beginning at the specified plane location.
; xx yy - Location on gameplay state plane B
; ss bb - State & block ID
; aa aa aa aa - Address of 96-byte array with dumped CRAM palettes
StampBlock:
	SetupFramePointer

	; TODO use IsoblenderGetRomBlockAddress on the second argument

	RestoreFramePointer
	rts

; Given a block ID and status, return the address to a 4x4 set of tiles.
; ss bb - Status and block ID
; Returns: aa aa aa aa - Address to first tile in a 4x4 set of tiles
;                        Null pointer if this operation could not complete successfully
GetRomBlockAddress:
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

GetRomBlockAddress_FindTiledata:
	move.w	a0, d0
	cmp.w	4(sp), d0			; Compare this status flag to the local status flag
	beq.s	GetRomBlockAddress_TileFound	; Iterate again if they don't match

	add.l	#518, a0			; One 4x4 tile block runs a total of 518 bytes (8*4 (32) for one block, times 4*4 (16) tiles) plus six byte header
	dbeq	d1, GetRomBlockAddress_FindTiledata

	; Tile wasn't found
	move.l	#0, d0				; Return null pointer
	bra.s	GetRomBlockAddress_Finally

GetRomBlockAddress_TileFound:
	move.l	a0, d0				; Recall that d0 holds the return address

GetRomBlockAddress_Finally:
	rts


; Determine if colour set [ cc cc cc cc ] fits into the palette located at [ pp pp pp pp ]
; cc cc cc cc - Colour set (16 entries padded by 0000)
; pp pp pp pp - Target palette
; Returns: 00 bb - 1 if it does, 0 if it does not
PaletteContainsSet:
	SetupFramePointer

	move.w	#0, -(sp)		; 6(sp) Current colour from palette to compare to colour from set
	move.w	#15, -(sp)		; 4(sp) Current counter for the palette loop
	move.w	#15, -(sp)		; 2(sp) Current counter for the set loop
	move.w	#0, -(sp)		; (sp) Current colour from set that we are looking for in target palette

	move.l	4(fp), a0		; a0 = Current colour in the colourset
	move.w	2(sp), d0		; Set up the next loop

PaletteContainsSet_ForEachColourSetEntry:
	move.w	d0, 2(sp)		; Save new counter

	move.w	(a0)+, (sp)		; Move next colour from set

	; Now root through the palette at 8(fp) and find (sp)
	move.l	8(fp), a1		; a1 = Current palette entry
	move.w	4(sp), d0		; Set up inner loop
PaletteContainsSet_ForEachColourSetEntry_ForEachPaletteEntry:
	move.w	d0, 4(sp)		; Save new counter

	move.w	(a1)+, 6(sp)	; Get colour to compare to

	move.w	(sp), d0
	move.w	6(sp), d1
	cmp.w	d0, d1
	beq.s	PaletteContainsSet_ForEachColourSetEntry_Next ; Now compare (sp) to 6(sp) - If they're equal, bail out early as this colour is in the palette

	; And we get here if the colours are not equal, keep looking
	move.w	4(sp), d0
	dbeq 	d0, PaletteContainsSet_ForEachColourSetEntry_ForEachPaletteEntry

	; Here, we looked through the palette for the colour at (sp) but it was not in the palette.
	; One colour not in the palette means this palette does not fit.
	bra.s	PaletteContainsSet_ReturnFalse

PaletteContainsSet_ForEachColourSetEntry_Next:
	move.w	2(sp), d0
	dbeq	d0, PaletteContainsSet_ForEachColourSetEntry	; Loop and jump out if we run out of items

	; Well, we made it here and never had to branch to return false
	; So the set must fit fully within the palette
	move.w	#1, d0
	bra.s PaletteContainsSet_Finally

PaletteContainsSet_ReturnFalse:
	move.w	#0, d0

PaletteContainsSet_Finally:
	PopStack 8
	RestoreFramePointer
	rts

; Given an index and a tile row, return one of 8 4-bit nibbles in the longword
; 00 ii - Index of nibble (0-7)
; ll ll ll ll - Tile row
; Returns: 00 nn - Nibble in the longword
GetTileNibble:
	move.l	6(sp), d0

GetTileNibble_Loop:
	tst.w	4(sp)
	beq.s	GetTileNibble_Filter

	lsr.l	#4, d0 			; Shift nibble over

	sub.w	#1, 4(sp)
	bra.s	GetTileNibble_Loop

GetTileNibble_Filter:
	andi.l	#$0000000F, d0	; All we want is the last nibble
	rts

; Given an index and tile row, and replacement value, swap the nibble for the provided nibble.
; 00 ii - Index of nibble (0-7)
; 00 rr - Replacement value for this nibble
; ll ll ll ll - Longword
; Returns: ll ll ll ll - Longword with nibble replaced
SetTileNibble:
	move.l	#$0000000F, d0	; NOT mask
	move.l	#0, d1
	move.w	6(sp), d1		; Value we will be overlaying onto longword

SetTileNibble_Loop:
	tst.w	4(sp)
	beq.s	SetTileNibble_Set

	lsl.l	#4, d0
	lsl.l	#4, d1			; Move both down the longword

	sub.w	#1, 4(sp)
	bra.s	SetTileNibble_Loop

SetTileNibble_Set:
	not.l	d0				; Invert to create a mask
	and.l 	d0, 8(sp)		; Use mask to remove nibble we are replacing
	or.l	d1, 8(sp)		; Overlay the nibble at the desired location

	move.l	8(sp), d0		; Return value
	rts

	endif