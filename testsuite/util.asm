	ifnd TESTSUITE_UTIL
TESTSUITE_UTIL = 1

	include 'testsuite/constants.asm'

	macro TestsuiteEmulatorExit
		move.b	#1, TESTSUITE_CONTROL_BYTE
	endm

	macro TestsuiteReportPass
		move.b	\1, TESTSUITE_DATA_BYTE
		move.b	#2, TESTSUITE_CONTROL_BYTE
	endm

	macro TestsuiteReportFail
		move.b	\1, TESTSUITE_DATA_BYTE
		move.b	#3, TESTSUITE_CONTROL_BYTE
	endm

	endif