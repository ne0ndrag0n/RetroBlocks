	ifnd H_DIFF_COMPRESSION
H_DIFF_COMPRESSION = 1

	include 'modules/sram/sram.asm'

	macro GetNextSramInstruction
		move.l	\2, -(sp)
		move.w	\1, -(sp)
		jsr _GetNextSramInstruction
		PopStack 6
	endm

; Given a position of an SRAM instruction, insert the full instruction into the space
; at the destination pointer and return the index of the next instruction.
; ii ii - Index of the current instruction in SRAM
; aa aa aa aa - Pointer to allocated space which can fit at least DIFF_MAX_SIZE bytes.
; Returns: ii ii - Index of the next instruction in SRAM
;
; Caveats:
; * Function results not defined if called with a value after the "Stop" (00) instruction.
_GetNextSramInstruction:
	EnableSram
	ReadSramLong 4(sp)
	DisableSram

	move.w  4(sp), d1
	addi.w	#4, d1			; add 4 to index to get to metadata
	move.w  d1, 4(sp)       ; index += 4

	move.l  6(sp), a0
	move.l  d0, (a0)		; Copy it to the memory at aa aa aa aa

	tst.b   d0
	beq.s   _GetNextSramInstruction_LastItem		; Return next index as last item

	move.l	a0, d0
	addi.l  #4, d0			; add 4 to address to place compression instruction data
	move.l  d0, a0			; addr += 4

	move.l  a0, -(sp)
	move.w  4+4(sp), -(sp)
	moveq	#0, d0
	move.b	3(a0), d0		; Reset d0 to zero and move the control byte to it
	lsl.w	#1, d0          ; Multiply control byte by 2 to get jump table index
	move.w  GetInstructionJumpTable( pc, d0.w ), d0
	jsr		GetInstructionJumpTable( pc, d0.w )			; Apply the jump table to get correct instruction metadata
	PopStack 6

	bra.s _GetNextSramInstruction_Finally

_GetNextSramInstruction_LastItem:
	move.w  #0, d0			; Clean out the word in the return value (from a Stop instruction only)
_GetNextSramInstruction_Finally:
	add.w   4(sp), d0		; Add the previous index to the jump table return value
	rts

; The following functions feature the same interface:
; ii ii - SRAM index of the data
; aa aa aa aa - Pointer to space sufficient to fit the destination data
; Returns: ii ii - Amount to advance the index
GetInstructionJumpTable:
	dc.w    GetStopInstruction - GetInstructionJumpTable
	dc.w	GetReplaceInstruction - GetInstructionJumpTable
	dc.w    GetRleInstruction - GetInstructionJumpTable
	dc.w	GetRleInstruction - GetInstructionJumpTable
	dc.w	GetRleInstruction - GetInstructionJumpTable
	dc.w    GetFloodFillInstruction - GetInstructionJumpTable

	macro GetStopInstructionSize
		move.w	#INSTR_SIZE_STOP, d0
	endm

	macro GetReplaceInstructionSize
		move.w	#INSTR_SIZE_REPLACE, d0
	endm

	macro GetRleInstructionSize
		move.w	#INSTR_SIZE_RLE, d0
	endm

	macro GetFloodFillInstructionSize
		move.w	#INSTR_SIZE_FLOOD_FILL, d0
	endm

GetStopInstruction:
	GetStopInstructionSize
	rts

GetReplaceInstruction:
	EnableSram
	ReadSramWord 4(sp)
	DisableSram

	move.l  6(sp), a0
	move.w	d0, 2(a0)		; Overlay word from SRAM onto external allocation

	GetReplaceInstructionSize
	rts

GetRleInstruction:
	EnableSram

	ReadSramByte 4(sp)
	move.l  6(sp), a0
	move.b	d0, 1(a0)		; Overlay byte from SRAM onto external allocation

	addi.w	#1, 4(sp)		; Increment SRAM position by one byte

	ReadSramWord 4(sp)
	move.l  6(sp), a0
	move.w  d0, 2(a0)		; Overlay word from SRAM onto external allocation

	DisableSram
	GetRleInstructionSize
	rts

GetFloodFillInstruction:
	EnableSram
	ReadSramLong 4(sp)
	DisableSram

	move.l 6(sp), a0
	move.l d0, (a0)				; Overlay long from SRAM onto external allocation

	GetFloodFillInstructionSize
	rts

; Given a coordinate x, y, z and a full SRAM compression instruction, determine if
; the instruction given in the two longs impacts the coordinate.
; xx yy - x, y coordinate
; 00 zz - z coordinate
; xx yy zz cc - Upper long of compression instruction
; ii ii ii ii - Lower long of compression instruction
; Returns:	00 bb
;			bb - 0 if the instruction does not affect this block
;				 1 if the instruction affects this block
InstructionAffects:
	move.w	#0, d0
	move.b  11(sp), d0
	lsl.w   #1, d0				; Grab cc and multiply it by 2
	move.w  InstructionAffectsJumpTable( pc, d0.w ), d0
	jmp		InstructionAffectsJumpTable( pc, d0.w )		; Jumptable!

; The following instructions feature the same interface as InstructionAffects
InstructionAffectsJumpTable:
	dc.w	StopInstructionAffects - InstructionAffectsJumpTable
	dc.w	ReplaceInstructionAffects - InstructionAffectsJumpTable
	dc.w	RleXInstructionAffects - InstructionAffectsJumpTable
	dc.w	RleYInstructionAffects - InstructionAffectsJumpTable
	dc.w	RleZInstructionAffects - InstructionAffectsJumpTable
	dc.w	FloodFillInstructionAffects - InstructionAffectsJumpTable

StopInstructionAffects:
ReplaceInstructionAffects:
	; This instruction affects the coordinate if it matches the coordinate in the instruction.
	move.b	4(sp), d0
	cmp.b   8(sp), d0
	bne.s   StopReplace_False

	move.b  5(sp), d0
	cmp.b   9(sp), d0
	bne.s   StopReplace_False

	move.b  7(sp), d0
	cmp.b	10(sp), d0
	beq.s   StopReplace_True

StopReplace_False:
	move.w	#0, d0
	rts
StopReplace_True:
	move.w  #1, d0
	rts

RleXInstructionAffects:
	; Note that a well-defined RLE instruction does not exceed the boundaries of the parent chunk.
	; Needle value must be >= base value and <= base + run

	move.b  4(sp), d0		; Get base value from instruction
	cmp.b   8(sp), d0       ; needle.x >= base.x ?
	blt.s   RleX_False

	move.b	8(sp), d1		; Get base value from instruction
	add.b   13(sp), d1		; Add run to get top end of the RLE instruction

	cmp.b   d1, d0			; needle.x <= base.x + run?
	ble.s	RleX_True

RleX_False:
	move.w	#0, d0
	rts
RleX_True:
	move.w	#1, d0
	rts

RleYInstructionAffects:
	; Note that a well-defined RLE instruction does not exceed the boundaries of the parent chunk.
	; Needle value must be >= base value and <= base + run

	move.b  5(sp), d0		; Get base value from instruction
	cmp.b   9(sp), d0       ; needle.y >= base.y ?
	blt.s   RleY_False

	move.b	9(sp), d1		; Get base value from instruction
	add.b   13(sp), d1		; Add run to get top end of the RLE instruction

	cmp.b   d1, d0			; needle.y <= base.y + run?
	ble.s	RleY_True

RleY_False:
	move.w	#0, d0
	rts
RleY_True:
	move.w	#1, d0
	rts

RleZInstructionAffects:
	; Note that a well-defined RLE instruction does not exceed the boundaries of the parent chunk.
	; Needle value must be >= base value and <= base + run

	move.b  7(sp), d0		; Get base value from instruction
	cmp.b   10(sp), d0      ; needle.z >= base.z ?
	blt.s   RleZ_False

	move.b	10(sp), d1		; Get base value from instruction
	add.b   13(sp), d1		; Add run to get top end of the RLE instruction

	cmp.b   d1, d0			; needle.z <= base.z + run?
	ble.s	RleZ_True

RleZ_False:
	move.w	#0, d0
	rts
RleZ_True:
	move.w	#1, d0
	rts

FloodFillInstructionAffects:
	; This instruction affects the coordinate if the recursive flood fill eventually includes
	; the given coordinate.
	; BIG TODO - May not want to use recursion
	; This is broken atm, don't use flood fill in beta
	move.w	#0, d0
	rts

	endif