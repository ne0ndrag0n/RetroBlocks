	ifnd H_FRAMEBUFFER_CONSTANTS
H_FRAMEBUFFER_CONSTANTS = 1

FRAMEBUFFER = $FF5400
FRAMEBUFFER_CONTROL_WORD = $4C000080

; 40 columns, times 28 rows, times 32 bytes per tile = 35840
FRAMEBUFFER_SIZE = 40*28*32

	endif