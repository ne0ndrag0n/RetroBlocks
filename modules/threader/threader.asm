	ifnd H_THREADER
H_THREADER = 1

; Set up the process control blocks (PCBs) for both game threads.
	macro ThreaderInit
		move.w	#THREAD_MAIN_STACK, (THREADER_MAIN_CONTEXT + THREADER_PCB_REGS + 4 + 2)	; Set the stack pointers for each thread
		move.w	#THREAD_BACK_STACK, (THREADER_BACK_CONTEXT + THREADER_PCB_REGS + 4 + 2)

		move.w	#$2000, (THREADER_MAIN_CONTEXT + THREADER_PCB_REGS + 4)		; Set default $2000 SR for both threads
		move.w  #$2000, (THREADER_BACK_CONTEXT + THREADER_PCB_REGS + 4)

		move.b  #THREAD_MAIN_TICKS, (THREADER_MAIN_PRIORITY_SETTING) 		; Main thread runs for 2/3 of the time
		move.b	#THREAD_BACK_TICKS, (THREADER_BACK_PRIORITY_SETTING) 		; Background thread runs 1/3 of the time

		move.b	#THREAD_MAIN_TICKS, (THREADER_REMAINING_TICKS)  			; Set the state of the thread engine up for the foreground thread
		move.b	#THREAD_BACK, (THREADER_NEXT_CONTEXT)						; Background thread will follow

		move.l	#RenderThread, (THREADER_MAIN_CONTEXT + THREADER_PCB_REGS)	; Set the thread PCs
		move.l  #UpdateThread, (THREADER_BACK_CONTEXT + THREADER_PCB_REGS)
	endm

	macro SaveContext
		movem.l	d0-d7/a0-a6, (\1)  						; Save all registers in this thread
		move.l  2(sp), (\1 + THREADER_PCB_REGS)			; Save return address as the program counter
		move.w  (sp), (\1 + THREADER_PCB_REGS + 4)		; Save the status register before the interrupt
		move.w  sp, d0									; Add 6 bytes and save the stack pointer itself
		addi.w	#6, d0
		move.w	d0, (\1 + THREADER_PCB_REGS + 4 + 2)	; (6 bytes to get past what the trap handler pushes)
	endm

	macro LoadContext
		move.l	#$00FF0000, sp
		move.w  (\1 + THREADER_PCB_REGS + 4 + 2), sp	; Load thread stack pointer
		move.l	(\1 + THREADER_PCB_REGS), -(sp)			; Push return address for vblank rte
		move.w	(\1 + THREADER_PCB_REGS + 4), -(sp)		; Push status register for vblank rte
		movem.l	(\1), d0-d7/a0-a6						; Load up all the registers for destination thread
	endm

; This address will be manipulated to jump back into a thread after vblank
; PC will be pushed first, followed by the SR when vblank is called.
ThreaderUpdate:
	; 1 tick every 16ms (NTSC), 63 ticks every 1008ms/1 second

	tst.b	(THREADER_REMAINING_TICKS)		; If there are no remaining ticks
	beq.s	ThreaderUpdate_SwapContext		; Switch context

	sub.b	#1, THREADER_REMAINING_TICKS	; Take a tick off and return if there are still remaining ticks
	jmp		VBlank_Update

ThreaderUpdate_SwapContext:
	tst.b   (THREADER_NEXT_CONTEXT)
	bne.s   ThreaderUpdate_SwitchToBackground	; 0 = Switch to Main, 1 = Switch to Background

ThreaderUpdate_SwitchToMain:
	move.b	#THREAD_BACK, (THREADER_NEXT_CONTEXT)								; The thread that follows main is the back thread
	move.b	(THREADER_MAIN_PRIORITY_SETTING), (THREADER_REMAINING_TICKS)		; Set main number of ticks as remaining ticks
	jmp VBlank_Update

ThreaderUpdate_SwitchToBackground:
	move.b	#THREAD_MAIN, (THREADER_NEXT_CONTEXT)								; The thread that follows back is the main thread
	move.b	(THREADER_BACK_PRIORITY_SETTING), (THREADER_REMAINING_TICKS)		; Set back number of ticks as remaining ticks
	jmp VBlank_Update

; Save a context when VBlank begins. This should also handle saving context for all of VBlank.
ThreaderSaveContext:
	tst.b	THREADER_NEXT_CONTEXT		; If next context is 0, we're on the background thread, and vice versa (it's reversed here)
	beq.s	ThreaderSaveContext_Back

ThreaderSaveContext_Main:
	SaveContext THREADER_MAIN_CONTEXT
	jmp VBlank_Begin

ThreaderSaveContext_Back:
	SaveContext THREADER_BACK_CONTEXT
	jmp VBlank_Begin

; Load a context when VBlank ends. ThreaderUpdate will handle swaps as they are needed.
ThreaderLoadContext:
	tst.b	THREADER_NEXT_CONTEXT		; If next context is 0, we're on the background thread, and vice versa (it's reversed here)
	beq.s	ThreaderLoadContext_Back

ThreaderLoadContext_Main:
	LoadContext	THREADER_MAIN_CONTEXT
	jmp VBlank_End

ThreaderLoadContext_Back:
	LoadContext	THREADER_BACK_CONTEXT
	jmp VBlank_End

	endif