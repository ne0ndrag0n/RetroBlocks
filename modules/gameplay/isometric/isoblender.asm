	ifnd H_GAMEPLAY_ISOMETRIC_ISOBLENDER
H_GAMEPLAY_ISOMETRIC_ISOBLENDER = 1

; Distributing colours across the three usermode palettes is a bin packing problem which is np-hard
;1. Copy palette of tile from ROM
;2. Determine if this palette fully fits into the target tile's palette. Lookup each colour in hashtable.
;   If it does, go to step 3
;   If it does not, go to step 6
;3. In the tile from ROM, update nibbles to correspond with their colours in the target tile's palette.
;4. OR the resulting tile over the existing tile
;5. Grab new tile + palette struct from ROM and go back to 1
;
;6. Attempt to insert new colours into the target tile's existing palette.
;    If they fit, go to step 3.
;    If they don't fit, go to step 7
;7. Begin dropping colours from the tile in order to reduce the load it places on the palettes.
;    Take the colour that occurs the least in this palette (e.g. a single blue pixel for water in the corner) and change
;    occurrences of it to transparency (0). Then, drop the colour from the colour set required for the new tile.
;
;    Repeat the process from step 2.
;
; * For index 0 nametable entries, find the nearest palette that can contain the new ROM subpalette.
;   This is where the entry point is for tiles' palettes. Use hashtable to determine if subpalette fits into each palette.
;   If no palettes can contain the entry, we drop the tile.

ISOBLENDER_TILE_HASHTABLE = $FF0100
ISOBLENDER_TILE_HASHTABLE_BUCKET_SIZE = 100

ISOBLENDER_PAL_HASHTABLE = ISOBLENDER_TILE_HASHTABLE + (255*ISOBLENDER_TILE_HASHTABLE_BUCKET_SIZE)
ISOBLENDER_PAL_HASHTABLE_BUCKET_SIZE = 30

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

	; Set up VRAM tile hashtable (for stamper)
	bsr.w InitHashtables

	; Using the rendertable, iterate each isometric block position
	; When iterating the third byte, move two 8x8 blocks over and one down each time.
	; Call BlendTile to overlay the top tile onto the bottom one.
	; And of course, use the selected worldgen.

	; Allocate necessary local variables
	move.w	#0, -(sp)															; 110(sp) Copy of coordinates used for iteration
	move.l	#$000F0F0F, -(sp)													; 106(sp) Remaining free space in 3 CRAM palettes
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

	subi.b	#1, 111(sp)			; Move -1 along the world in the y dimension

	subi.w	#1, (sp)			; Decrement remaining stamps on this origin

	bra.s	RenderBoard_ExecuteStamper

RenderBoard_NextStamperIteration:
	subi.b	#1, 4(fp)			; origin x-1
	addi.b	#1, 5(fp)			; origin y+1
	move.w	4(fp), 110(sp)		; Set up iteration counter for next iteration of stamper

	bra.s	RenderBoard_StamperIteration

RenderBoard_Finally:
	PopStack 96 + 16
	RestoreFramePointer
	rts

; Stamp a 4x4 block (16 tiles total) beginning at the specified plane location.
; xx yy - Location on gameplay state plane B
; ss bb - State & block ID
; aa aa aa aa - Address of 96-byte array with dumped CRAM palettes + longword at end detailing free space remaining
StampBlock:
	SetupFramePointer

	move.l	#0, -(sp)		; 36(sp) - Address of the block we are stamping
	move.w	#0, -(sp)		; 34(sp) - Target nametable entry per iteration
	move.w	#$0404, -(sp)	; 32(sp) - x, y tiles remaining
	Allocate #32			; (sp) - Current block being worked on

	IsoblenderGetRomBlockAddress 6(fp)
	move.l	d0, 36(sp)					; Get and save the ROM block address

	; TODO use IsoblenderGetRomBlockAddress on the second argument

	PopStack 32 + 8
	RestoreFramePointer
	rts

; Given a tile's palette and the total list of VRAM palettes, get a palette for the given ROM tile palette,
; and adjust VRAM palettes as necessary.
; pp pp - Plane nametable entry
; rr rr rr rr - Palette associated with incoming ROM tile + header
; aa aa aa aa - Address of 96-byte VRAM palette dump + longword at end detailing free space remaining
; Returns: 00 ii - Palette offset (00, 20, or 40)
GetBlockTilePalette:
	SetupFramePointer

	; TODO

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

; Set up the VRAM tile hashtables.
;	* There are 255 buckers accessible via Pearson hash.
;	* Each bucket contains ISOBLENDER_TILE_HASHTABLE_BUCKET_SIZE entries, in bytes.
;	* Half of ISOBLENDER_TILE_HASHTABLE_BUCKET_SIZE is the number of words storable in each bucket.
;	* Buckets are full when an $FFFF entry can't be located in the bucket.
;	* A usermode exception is thrown when a bucket is full.
InitHashtables:
	move.l	#ISOBLENDER_TILE_HASHTABLE, a0
	move.w	#( ISOBLENDER_TILE_HASHTABLE_BUCKET_SIZE / 2 ) - 1, d0
InitHashtables_Loop:
	move.w	#$FFFF, (a0)+
	dbeq	d0, InitHashtables_Loop

	move.l	#ISOBLENDER_PAL_HASHTABLE, a0
	move.w	#( ISOBLENDER_PAL_HASHTABLE_BUCKET_SIZE / 2 ) - 1, d0
InitHashtables_Loop2:
	move.w	#$FFFF, (a0)+
	dbeq	d0, InitHashtables_Loop2
	rts

; Using Pearson hash, insert the given pal/col (PALlete/COLour) byte into the hashtable.
; 00 pc - Upper nibble of byte has palette (1-3), lower nibble of byte has index (1-15)
PaletteHashtableInsert:
	move.l	#ISOBLENDER_PAL_HASHTABLE, a0
	rts

	endif