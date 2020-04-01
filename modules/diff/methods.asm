	ifnd H_DIFF_METHODS
H_DIFF_METHODS = 1

	macro SramContainsDiff
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		jsr _SramContainsDiff
		PopStack 4
	endm

; Determine if the given coordinate is accounted for in any
; SRAM instruction. If so, return the SRAM offset of the instruction.
; xx yy zz cc
; ii ii ii ii
; nn nn - Current instruction offset
; nn nn - Former instruction offset
; rr rr rr rr
; xx yy - x, y coordinates
; 00 zz - z coordinates
; Returns:	00 bb rr rr
;           bb - 0 if not found in SRAM, 1 if found.
;           rr rr - The numeric index of the instruction in SRAM.
_SramContainsDiff:
	SetupFramePointer
	Allocate #( DIFF_MAX_SIZE + 4 )

	move.w	#0, DIFF_MAX_SIZE(sp)			; DIFF_MAX_SIZE(sp) will store the word for where our current instruction is

_SramContainsDiff_Loop:
	move.w  DIFF_MAX_SIZE(sp), DIFF_MAX_SIZE+2(sp)	; Save the old instruction offset before it's overwritten by the next one
	GetNextSramInstruction DIFF_MAX_SIZE(sp), sp
	move.w	d0, DIFF_MAX_SIZE(sp)			; Store the location of the next instruction in SRAM

	tst.b	3(sp)
	bne.s   _SramContainsDiff_IsSameChunk	; If this is a "Stop" instruction, end

	move.l	#0, d0							; Nothing found in SRAM, no instruction to return
	bra.s	_SramContainsDiff_End

_SramContainsDiff_IsSameChunk:
	move.w  6(fp), -(sp)
	move.w	4(fp), -(sp)
	move.w  1(sp), -(sp)
	andi.w  #$00FF, (sp)
	move.w  (sp), -(sp)
	jsr DiffIsSameChunk
	PopStack 8							; Call IsSameChunk to see if the x, y, z are in the same chunk

	tst.w	d0
	beq.s	_SramContainsDiff_Loop		; Loop back up if the result of the above call was 00 00

	; If the item above returns 00 01, then we need to call the more expensive InstructionAffects method
	; which will tell us whether or not x, y, and z are accounted for in this instruction.
	move.l	4(sp), -(sp)
	move.l  4(sp), -(sp)
	move.w  6(fp), -(sp)
	move.w	4(fp), -(sp)
	jsr InstructionAffects
	PopStack 12

	; If this instruction does not affect the item - continue on the loop until we run out of instructions
	tst.w	d0
	beq.s   _SramContainsDiff_Loop

	; If this instruction affects the item - assume it is the only one and return true
	andi.l  #$000000FF, d0				; Erase junk in the upper bits
	lsl.l   #8, d0
	lsl.l   #8, d0						; Make room for a word
	move.w  DIFF_MAX_SIZE+2(sp), d0     ; Pull up the old SRAM offset

_SramContainsDiff_End:
	Deallocate #( DIFF_MAX_SIZE + 4 )
	RestoreFramePointer
	rts

	endif