; Testsuite works with MAME to run functions/methods on the MD, report results via the debugger,
; and then process the result output using external tool.

	jmp BeginTests

	include 'testsuite/util.asm'

BeginTests:
	move.w	#$DEAD, d0

	TestsuiteReportPass #$B0
	TestsuiteEmulatorExit

	; contingency
TestLoop:
	bra.s TestLoop
