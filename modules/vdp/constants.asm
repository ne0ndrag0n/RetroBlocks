 ifnd H_STATIC_VDP_CONSTANTS
H_STATIC_VDP_CONSTANTS = 1

  ; 0 = 128 for any given sprite value
  ; To go from real to retarded sprite coordinates, add 128/$80

; VDP access modes
VDP_CRAM_READ=$00000020
VDP_CRAM_WRITE=$C0000000
VDP_VRAM_READ=$00000000
VDP_VRAM_WRITE=$40000000
VDP_VSRAM_READ=$00000010
VDP_VSRAM_WRITE=$40000010
VDP_DMA_ADDRESS=$00000080

; Each word in VSRAM can only be 0-2047
VDP_VSRAM_MASK = $07FF

; VDP status
VDP_STATUS_FIFO_EMPTY=$0200
VDP_STATUS_FIFO_FULL=$0100
VDP_STATUS_VINT_PENDING=$0080
VDP_STATUS_SPRITE_OVERFLOW=$0040
VDP_STATUS_SPRITE_COLLISION=$0020
VDP_STATUS_ODD_FRAME=$0010
VDP_STATUS_VBLANK=$0008
VDP_STATUS_HBLANK=$0004
VDP_STATUS_DMA=$0002
VDP_STATUS_PAL=$0001

VDP_DATA=$00C00000
VDP_CONTROL=$00C00004
VDP_HVCOUNTER=$00C00008

VDP_PAL_0=$00
VDP_PAL_1=$20
VDP_PAL_2=$40
VDP_PAL_3=$60

; Use these flags for register 0 state definitions
VDP_REG00_DEFAULTS = $04
VDP_HBLANK_ENABLED = $16

; Use these flags for register 1 state definitions
VDP_MASTER_SYSTEM = $00
VDP_MEGADRIVE = $04
VDP_NTSC = $00
VDP_PAL = $08
VDP_DMA_ENABLED = $10
VDP_DMA_DISABLED = $00
VDP_VBLANK_ENABLED = $20
VDP_VBLANK_DISABLED = $00
VDP_SCREEN_ENABLED = $40
VDP_SCREEN_DISABLED = $00
VDP_128K_VRAM = $80
VDP_64K_VRAM = $00

VDP_FONT_PATTERN_LOCATION = $0000
VDP_USER_PATTERN_LOCATION = $0C00

 endif
