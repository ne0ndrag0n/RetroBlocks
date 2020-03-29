  ifnd H_SRAM
H_SRAM = 1

; Takes an address argument
; Places the SRAM address in a0
  macro GetSramBaseAddress
    move.l  #0, d1
	move.w  \1, d1
	lsl.w   #1, d1
	addi.w  #1, d1
	addi.l  #SRAM_START, d1
	move.l  d1, a0				 ; Formula for SRAM offset is SRAM_START + ( ( operand * 2 ) + 1 )
  endm

  macro EnableSram
	move.b	#SRAM_ENABLE, (SRAM_CONTROL)
  endm

  macro DisableSram
	move.b  #SRAM_DISABLE, (SRAM_CONTROL)
  endm

; \1 - SRAM offset to be read (word size)
; Desired value will be returned in d0
  macro ReadSramByte
	GetSramBaseAddress \1

	move.b  (a0), d0             ; Grab sram byte and place into d0
  endm

; \1 - SRAM offset to be read (word size)
; Desired value will be returned in d0
  macro ReadSramWord
	GetSramBaseAddress \1

	move.b  (a0), d0			; Grab sram byte
	lsl.l   #8, d0				; Free up room for another byte in d0
	move.b  2(a0), d0			; Grab next byte(s)
  endm

; \1 - SRAM offset to be read (word size)
; Desired value will be returned in d0
  macro ReadSramLong
	GetSramBaseAddress \1

	move.b  (a0), d0			; Grab sram byte
	lsl.l   #8, d0				; Free up room for another byte in d0
	move.b  2(a0), d0			; Grab next byte(s)
	lsl.l   #8, d0
	move.b  4(a0), d0
	lsl.l   #8, d0
	move.b  6(a0), d0
  endm

; \1 - SRAM offset to be read (word size)
; \2 - Item to be written
  macro WriteSramByte
	GetSramBaseAddress \1

	move.b  \2, (a0)
  endm

; \1 - SRAM offset to be read (word size)
; \2 - Item to be written
  macro WriteSramWord
	GetSramBaseAddress \1

	move.b  \2, 2(a0)
	lsr.l   #8, \2
	move.b  \2, (a0)
  endm

; \1 - SRAM offset to be read (word size)
; \2 - Item to be written
  macro WriteSramLong
	GetSramBaseAddress \1

	move.b  \2, 6(a0)
	lsr.l   #8, \2
	move.b  \2, 4(a0)
	lsr.l   #8, \2
	move.b  \2, 2(a0)
	lsr.l   #8, \2
	move.b  \2, (a0)
endm

  endif