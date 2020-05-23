	ifnd H_GAMEPLAY_ISOMETRIC_ISOBLENDER
H_GAMEPLAY_ISOMETRIC_ISOBLENDER = 1

; Process of stamping tile:

; 1. Create a local buffer for tile due to be stamped or evaluated (zero-out).
; If there is an existing palette (destination tile palette is nonzero):
;   * Existing palette = existing tile. Dump the tile to local buffer.
; If there is not an existing palette (destination tile palette is zero):
;   * Copy ROM tile to local buffer.

; 2. Find a palette for the incoming tile.
; If there is an existing palette (destination tile palette is nonzero):
; 	* Attempt to add colours to existing palette's free space (reusing existing colours in the process).
;   * If we can't, drop the least common colours from the palette and reattempt above process.
;     This will end up modifying the original tile - nibbles containing least common colour turn to "0"
; If there is not an existing palette (destination tile palette is zero):
;   * Using the color list for the ROM tile, assign a palette that has both the most overlap and most free space.
;   * If we can't do this, drop least common pixel from buffer, and repeat above process until it fits.

; 3. Build a local copy of the tile using the resulting tile.
; If there is an existing tile:
;   * Overlay incoming tile's nonzero nibbles over buffer's nibbles.
;	  As we go, replace nibbles with the correlates in the palette.
;   * Take Pearson hash of the tile contained in the buffer and determine
;     if it is already present in VRAM.
;		* If it is, use it.
;		* If it isn't, create a new tile and send it to VRAM, then use it.
; If there is not an existing tile:
;   * Take Pearson hash of the tile contained in the buffer and determine
;     if it is already present in VRAM.
;		* If it is, use it.
;		* If it isn't, create a new tile and send it to VRAM, then use it.

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

	macro IsoblenderPaletteHashtableInsert
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		bsr	PaletteHashtableInsert
		PopStack 4
	endm

	macro IsoblenderGetPaletteIndices
		move.l	\2, -(sp)
		move.w	\1, -(sp)
		bsr GetPaletteIndices
		PopStack 6
	endm

	macro IsoblenderGetPaletteFreeSpace
		move.l	\1, -(sp)
		bsr GetPaletteFreeSpace
		PopStack 4
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

	move.w	#0, -(sp)		; 44(sp) - x value to add to nametable per tile iteration
							; 45(sp) - y value to add to nametable per tile iteration
	move.l	#0, -(sp)		; 40(sp) - Address of the current tile we are working on
	move.l	#0, -(sp)		; 36(sp) - Address of the palette for all subsequent tiles
	move.w	#0, -(sp)		; 34(sp) - Target nametable entry per iteration
	move.w	#$0303, -(sp)	; 32(sp) - x tiles remaining
							; 33(sp) - y tile remaining
	Allocate #32			; (sp) - Local buffer for block due to be stamped

	IsoblenderGetRomBlockAddress 6(fp)
	addi.l	#2, d0						; Skip the status flag
	move.l	d0, a0
	move.l	(a0)+, 36(sp)				; Save the pointer in ROM to local palette pointer
										; Postincrement

	move.l  a0, 40(sp)					; Save the value of a0 as the first tile to be processed

	; Stamp each tile bound by the Y-value in 32(sp)
	move.b	33(sp), d0
StampBlock_ForEachTileY:
	move.b	d0, 33(sp)

	move.b	#3, 32(sp)						; 4 x-tile stamps for every row
	move.b	32(sp), d0
StampBlock_ForEachTileX:
	move.b	d0, 32(sp)

	; 1. Create a local buffer for tile due to be stamped or evaluated (zero-out).
	Deallocate #32
	rept 8
	move.l	#0, -(sp)
	endr									; Erase buffer for tile

	; Now need to determine if there is already a tile at this nametable entry
	; We do this by going off whether or not the full word is 0
	move.w	#0, d0
	move.b	32(sp), d0
	subi.w	#3, d0
	MathAbs d0
	move.b	d0, 44(sp)						; Subtract 3 from x remaining and take abs

	move.w	#0, d0
	move.b	33(sp), d0
	subi.w	#3, d0
	MathAbs d0
	move.b	d0, 45(sp)						; Subtract 3 from y remaining and take abs

	move.b	4(fp), d0
	add.b	d0, 44(sp)						; Add original X to X adjustment

	move.b	5(fp), d0
	add.b	d0, 45(sp)						; Add original Y to Y adjustment

	VdpGetNametableEntry 44(sp), #VDP_GAMEPLAY_PLANE_B	; Get the nametable word
	move.w	d0, 34(sp)						; Save it

	tst.w	d0
	beq.s	StampBlock_ForEachTileX_NewTile	; If the word is 0, it's a new tile.

StampBlock_ForEachTileX_ExistingTile:
	; Dump tile to local buffer
	andi.w	#$07FF, d0						; Clear all info except the tile ID
	VdpCopyVramTile d0, sp					; Dump tile of this ID

	; Attempt to add colours to existing palette's free space (reusing existing colours in the process).
	; TODO: Call IsoblenderAddColorsToPalette

	; If IsoblenderAddPalette returns 0, the incoming palette did not fit
	; Call IsoblenderDropLeastCommon on the dumped tile and repeat until it does fit.

	; ...
	bra.s	StampBlock_ForEachTileX_NextX

StampBlock_ForEachTileX_NewTile:
	; ...
	nop

StampBlock_ForEachTileX_NextX:
	move.b	32(sp), d0
	dbeq	d0, StampBlock_ForEachTileX

	move.b	33(sp), d0
	dbeq	d0, StampBlock_ForEachTileY

	PopStack 32 + 14
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
	move.w	#( (ISOBLENDER_TILE_HASHTABLE_BUCKET_SIZE*255) / 2 ) - 1, d0
InitHashtables_Loop:
	move.w	#$FFFF, (a0)+				; FFFF is the sentinel value in the tile hashtable
	dbeq	d0, InitHashtables_Loop

	move.l	#ISOBLENDER_PAL_HASHTABLE, a0
	move.w	#( (ISOBLENDER_PAL_HASHTABLE_BUCKET_SIZE*255) / 2 ) - 1, d0
InitHashtables_Loop2:
	move.w	#$0000, (a0)+				; 00 is the sentinel value in the pal/col hashtable
	dbeq	d0, InitHashtables_Loop2
	rts

; Using Pearson hash, insert the given pal/col (PALlete/COLour) byte into the hashtable.
; 0c cc - Colour (used as key)
; 00 pi - Upper nibble of byte has palette (0-2 *user palette* index), lower nibble of byte has index (1-15) (used as value)
PaletteHashtableInsert:
	move.l	sp, d0
	addi.l	#4, d0
	MathPearsonHash d0, #2

	; d0 now contains bucket index
	; Find first 00 element in the bucket, and overwrite it

	move.l	#ISOBLENDER_PAL_HASHTABLE, a0
	andi.l	#$000000FF, d0
	mulu.w	#ISOBLENDER_PAL_HASHTABLE_BUCKET_SIZE, d0
	add.l	d0, a0

	move.w	#( ISOBLENDER_PAL_HASHTABLE_BUCKET_SIZE - 1 ), d1

PaletteHashtableInsert_Loop:
	cmpi.b	#0, (a0)
	beq.s	PaletteHashtableInsert_Found

	add.l	#1, a0

	dbeq	d1, PaletteHashtableInsert_Loop

	; Free spot in bucket not found.
	; Throw trap #00 and freeze at UserError in debugger - This is a program bug
	trap 	#0

PaletteHashtableInsert_Found:
	move.b	7(sp), (a0)		; Set value in bucket
	rts

; Given a colour, return a word representing the index of the colour in each of the three palettes.
; If the colour does not occur in the palette, the index for that entry will be 00.
;
; NOTE: Results undefined for palettes containing duplicate entries (this should not occur in normal isoblender operation)
;
; 0c cc - Colour to search for in palettes.
; aa aa aa aa - Address of VRAM palette dump structure. Used to verify that the entry in the bucket is the same colour.
; Returns: 0t sf
;			t - 1-15 index in third palette
;			s - 1-15 index in second palette
;			f - 1-15 index in first palette
GetPaletteIndices:
	SetupFramePointer

	move.w	#0, -(sp)		; 2(sp) The current index of the bucket search
	move.w	#0, -(sp)		; (sp) The result colours

	move.l 	fp, d1
	addi.l	#4, d1
	MathPearsonHash d1, #2	; Get hash of sample colour

	; Byte in d0 now contains the bucket index
	move.l	#ISOBLENDER_PAL_HASHTABLE, a0
	andi.l	#$000000FF, d0
	mulu.w	#ISOBLENDER_PAL_HASHTABLE_BUCKET_SIZE, d0
	add.l	d0, a0

	; a0 now contains bucket address
	; Search bucket until we hit a 00 byte or exceed the bucket size
	move.w	#( ISOBLENDER_PAL_HASHTABLE_BUCKET_SIZE - 1 ), d1
	andi.l	#$000000FF, d0			; Go ahead and clean up d0 again for byte operations
GetPaletteIndices_SearchBucket:
	move.w	d1, 2(sp)				; Rewrite d1 to 2(sp) for dbeq instruction

	move.b	(a0), d0				; Current byte from current bucket

	tst.b	d0
	beq.s	GetPaletteIndices_Finally	; 00 = sentinel value to stop

	; Get palette index and convert that to a base address we can hop to
	andi.b	#$F0, d0
	lsl.b	#1, d0		; Only need to mask + shift it over by 1 to get the palette offset!

	move.l	6(fp), a1
	add.l	d0, a1		; Get address of palettes and add offset computed in previous step

	move.b	(a0), d0
	andi.b	#$0F, d0	; Now grab bucket value again and take only the palette offset
	lsl.b	#1, d0		; Multiply it by 2 to get byte index from word index
	add.l	d0, a1		; Increment palette pointer to the exact location of the colour

	move.w	(a1), d0	; d0 = the colour at that location
	cmp.w	4(fp), d0
	bne.s	GetPaletteIndices_Next

	; If we got here, that's a hit for this bucket entry
	; For the given palette, attach the palette index number to the byte entry

	move.l	#0, d0			; Clear the register

	move.b	(a0), d0
	andi.b	#$F0, d0
	lsr.b	#2, d0			; This time we want the raw number of the palette, then multiply it by 4 bits
							; Shift right 4, then we'd need to shift left by 2 to multiply by 4
							; Therefore, only shift right by 2

	move.w	#0, d1
	move.b	(a0), d1
	andi.b	#$0F, d1		; Grab palette index (word)
	lsl.w	d0, d1			; Shift left by the user palette amount * 4 (already bitshifted above)
	or.w	d1, (sp)		; "OR" the result onto the result word

GetPaletteIndices_Next:
	add.l	#1, a0

	move.w	2(sp), d1		; Service 2(sp) using d1 register
	dbeq	d1, GetPaletteIndices_SearchBucket

GetPaletteIndices_Finally:
	move.w	(sp)+, d0		; Result counter goes from stack to result register
	PopStack 2
	RestoreFramePointer
	rts

; Given a palette, add the colours to the palette, skipping colours that are already in the given palette.
; a1 a1 a1 a1 - Address of the incoming palette
; aa aa aa aa - Address of VRAM palette structure
; 00 ii - Index of the destination palette
; Returns: 00 bb - 1 if the operation was successful, 0 if not.
AddColorsToPalette:
	SetupFramePointer

	move.l	#0, -(sp)		; 2(sp) Address-sized scratch space
	move.w	#0, -(sp)		; (sp) Number of colours shared across both palettes
							; 1(sp) Loop counter, various loops

	; Get the amount of colours the destination palette shares with the incoming palette.
	move.l	4(fp), a0
	add.l	#1, a0			; Incoming palette address, and skip first item which is always 0000

AddColorsToPalette_Loop:
	tst.w	(a0)
	beq.s	AddColorsToPalette_Loop_End		; End when 0000 is encountered

	move.l	a0, 2(sp)		; Save a0 when we go into calling GetPaletteIndices
	IsoblenderGetPaletteIndices (a0), 8(fp)
	move.l	2(sp), a0		; Put it right back

	; If result of IsoblenderGetPaletteIndices is 0, then we can quickly determine
	; that the colour does not exist in the target palette (or any other palette).
	tst.w 	d0
	beq.s	AddColorsToPalette_EntryNotInTargetPalette

	; If the result of IsoblenderGetPaletteIndices is non-0, we need to determine
	; if it falls within the index of the destination palette by removing all other
	; palettes it occurs in. If the result of that `andi` operation is nonzero,
	; then the colour occurs in the target palette.

	move.w	12(fp), d1		; Move palette index to d1
	lsl.w	#1, d1			; Times 2
	move.w	AddColorsToPalette_JumpTable( pc, d1.w ), d1
	jmp		AddColorsToPalette_JumpTable( pc, d1.w )		; Apply jump table

AddColorsToPalette_JumpTable:
	dc.w	AddColorsToPalette_FirstPaletteMask - AddColorsToPalette_JumpTable
	dc.w 	AddColorsToPalette_SecondPaletteMask - AddColorsToPalette_JumpTable
	dc.w	AddColorsToPalette_ThirdPaletteMask - AddColorsToPalette_JumpTable

AddColorsToPalette_FirstPaletteMask:
	andi.w	#$000F, d0
	bra.s	AddColorsToPalette_CheckEntry

AddColorsToPalette_SecondPaletteMask:
	andi.w	#$00F0, d0
	bra.s	AddColorsToPalette_CheckEntry

AddColorsToPalette_ThirdPaletteMask:
	andi.w	#$0F00, d0

AddColorsToPalette_CheckEntry:
	; Nonzero = Color already exists in palette
	tst.w	d0
	beq.s	AddColorsToPalette_EntryNotInTargetPalette

AddColorsToPalette_EntryInTargetPalette:
	; Well, there's nothing to really do here except go to the next one
	nop

AddColorsToPalette_EntryNotInTargetPalette:
	; TODO
	nop

AddColorsToPalette_Loop_End:
	PopStack 6
	RestoreFramePointer
	rts

; Count the number of free items in the given palette. This assumes a *compacted* palette, meaning that the free space
; begins at the first 0000 entry *that is not located at index 0.*
; aa aa aa aa - The palette
; Returns: 00 cc - Amount of free items in the palette.
GetPaletteFreeSpace:
	move.l	4(sp), a0
	add.l	#2, a0		; Skip index #0

	move.w	#15, d0		; Assume 15 free entries
	move.w	#14, d1		; Loop through items 1-15 only

GetPaletteFreeSpace_Loop:
	tst.w	(a0)+
	beq.s	GetPaletteFreeSpace_Finally

	subi.w	#1, d0		; Item was in use
	dbeq	d1, GetPaletteFreeSpace_Loop

GetPaletteFreeSpace_Finally:
	rts

	endif