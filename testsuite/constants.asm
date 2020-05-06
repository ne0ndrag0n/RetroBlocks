	ifnd TESTSUITE_CONSTANTS
TESTSUITE_CONSTANTS = 1

TESTSUITE_CONTROL_BYTE = $A14102
TESTSUITE_ANNOTATION   = $A14103

	macro TestsuiteEmulatorExit
		move.b	#1, TESTSUITE_CONTROL_BYTE
	endm

	macro TestsuiteReportPass
		move.b	#2, TESTSUITE_CONTROL_BYTE
	endm

	macro TestsuiteReportFail
		move.b	#3, TESTSUITE_CONTROL_BYTE
	endm

	macro TestsuitePrint
		move.l	#\1, a0

	TestsuitePrint_Loop\@:
		tst.b	(a0)
		beq.s	TestsuitePrint_End\@

		move.b	(a0)+, TESTSUITE_ANNOTATION
		bra.s TestsuitePrint_Loop\@

	TestsuitePrint_End\@:
	endm

	endif