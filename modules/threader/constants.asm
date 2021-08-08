	ifnd H_THREADER_CONSTANTS
H_THREADER_CONSTANTS = 1

THREAD_MAIN = $00
THREAD_BACK = $01

THREAD_MAIN_TICKS = 57
THREAD_BACK_TICKS = 3

; Threader priority settings follow tick count in the FF0010 block
; Byte-size counts in ticks
THREADER_MAIN_PRIORITY_SETTING = $FF0016
THREADER_BACK_PRIORITY_SETTING = $FF0017
THREADER_REMAINING_TICKS       = $FF0018
THREADER_NEXT_CONTEXT          = $FF0019

; 2 sets of 8 4-byte registers
; One long for saved program counter (4)
; One status register of word size (2)
; One word register for the current stack pointer before context switch (2)
THREADER_PCB_REGS     = 8*4*2
THREADER_PCB_SIZE     = THREADER_PCB_REGS + 4 + 2 + 2

THREADER_MAIN_CONTEXT = $FF0020
THREADER_BACK_CONTEXT = THREADER_MAIN_CONTEXT + THREADER_PCB_SIZE

; Main thread's stack runs from F800 - FFFF
; Background thread's stack runs from EFFF - F7FF
; Each thread should get ~2K stack
THREAD_MAIN_STACK = $FFFC
THREAD_BACK_STACK = THREAD_MAIN_STACK - 4096

	endif

; ll ll ll ll sr sr wr wr 00