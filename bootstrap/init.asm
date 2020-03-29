 include 'modules/z80/constants.asm'
 include 'modules/interrupts/constants.asm'

Start:
	DisableInterrupts

SecurityCheck:
  move.b  (REG_HWVERSION), d0
  andi.b  #$0F, d0
  beq.b   InitController         ; check HW version, if it's zero, skip the TMSS routine
  move.l  #'SEGA', (REG_TMS)     ; write SEGA to TMSS register to enable VDP

	; Set stack pointer all the way to end of Genesis RAM
	move.l #$00FFFFFC, a7

	RequestZ80Bus
	ResetZ80
	jsr WaitForZ80Bus

InitController:
  move.b #$40, (CTRL_1_CONTROL)
  move.b #$40, (CTRL_1_DATA)
  move.b #$40, (CTRL_2_CONTROL)
  move.b #$40, (CTRL_2_DATA)
  move.b #$40, (ACCESSORY_CONTROL)
  move.b #$40, (ACCESSORY_DATA)

	ReturnZ80Bus

InitVDP:
	lea 		(VDPInitData), a0
	move.w	#( (VDPInitDataEnd - VDPInitData)/2 ) - 1, d1
InitVDPDataLoop:
	move.w	(a0)+, (VDP_CONTROL)
	dbf			d1, InitVDPDataLoop

ClearCRAM:
	move.l  #VDP_CRAM_WRITE,(VDP_CONTROL)
	move.w  #$003f, d1
ClearCRAMLoop:
	move.w  #$0000, (VDP_DATA)
	dbf			d1, ClearCRAMLoop

	bsr.w		ClearVRAM

ClearRAM:
	lea			RAM_START, a0
	move.w	#(RAM_END - RAM_START), d1
ClearRAMLoop:
	move.w	#$0000, (a0)+
	dbf			d1, ClearRAMLoop

InitEcho:
  lea     SndPointerList, a0
  bsr.w   Echo_Init

	EnableInterrupts
