; Testsuite works with MAME to run functions/methods on the MD, report results via the debugger,
; and then process the result output using external tool.

	jmp BeginTests

	include 'testsuite/util.asm'

BeginTests:

QuickExample:
	move.w	#$DEAD, d0

	cmpi.w	#$DEAD, d0
	beq.s	QuickExample_Success

	TestsuiteReportFail #0
	bra.s TestsComplete

QuickExample_Success:
	TestsuiteReportPass #0

TestsComplete:
	TestsuiteEmulatorExit

	; contingency
TestLoop:
	bra.s TestLoop
