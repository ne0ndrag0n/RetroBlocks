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
_GetNextSramInstruction:
	EnableSram
	ReadSramLong 4(sp)
	DisableSram

	move.l  6(sp), a0
	move.l  d0, (a0)		; Copy it to the memory at aa aa aa aa

	move.w  4(sp), d0
	addi.w	#4, d0			; add 4 to index to get to metadata
	move.w  d0, 4(sp)       ; index += 4

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

	add.w   4(sp), d0		; Add the previous index to the jump table return value
	rts

; The following functions feature the same interface:
; ii ii - SRAM index of the data
; aa aa aa aa - Pointer to space sufficient to fit the destination data
; Returns: ii ii - Amount to advance the index
GetInstructionJumpTable:
	dc.w	GetReplaceInstruction - GetInstructionJumpTable
	dc.w    GetRleXInstruction - GetInstructionJumpTable
	dc.w	GetRleYInstruction - GetInstructionJumpTable
	dc.w	GetRleZInstruction - GetInstructionJumpTable
	dc.w    GetFloodFillInstruction - GetInstructionJumpTable

GetReplaceInstruction:
	move.l	#0, -(sp)		; Allocate long for load options

	EnableSram
	ReadSramWord 4+4(sp)
	DisableSram

	move.w	d0, 2(sp)		; Overlay word from SRAM onto local allocation
	move.l  6+4(sp), a0
	move.l	(sp), (a0)		; Move local allocation onto the external allocation

	PopStack 4
	move.w	#INSTR_SIZE_REPLACE, d0
	rts

	macro GetRleInstruction
		move.l	#0, -(sp)		; Allocate long for load options

		EnableSram

		ReadSramByte 4+4(sp)
		move.b	d0, 1(sp)		; Overlay byte from SRAM onto local allocation

		addi.w	#1, 4+4(sp)		; Increment SRAM position by one byte

		ReadSramWord 4+4(sp)
		move.w  d0, 2(sp)		; Overlay word from SRAM onto local allocation

		DisableSram

		move.l  6+4(sp), a0
		move.l	(sp), (a0)		; Move local allocation onto the external allocation

		PopStack 4
	endm

GetRleXInstruction:
	GetRleInstruction
	move.w	#INSTR_SIZE_RLE_X, d0
	rts

GetRleYInstruction:
	GetRleInstruction
	move.w	#INSTR_SIZE_RLE_Y, d0
	rts

GetRleZInstruction:
	GetRleInstruction
	move.w	#INSTR_SIZE_RLE_Z, d0
	rts

GetFloodFillInstruction:
	move.l	#0, -(sp)		; Allocate long for load options

	EnableSram

	ReadSramWord 4+4(sp)
	move.w	d0, (sp)		; Overlay word from SRAM onto local allocation

	addi.w	#2, 4+4(sp)		; Increment SRAM position by 2 bytes

	ReadSramWord 4+4(sp)
	move.w  d0, 2(sp)		; Overlay word from SRAM onto local allocation

	DisableSram

	move.l  6+4(sp), a0
	move.l	(sp), (a0)		; Move local allocation onto the external allocation

	PopStack 4
	move.w	#INSTR_SIZE_FLOOD_FILL, d0
	rts

	endif