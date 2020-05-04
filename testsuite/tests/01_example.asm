Test1:
	move.w	#$DEAD, d0

	cmpi.w	#$DEAD, d0
	beq.s	QuickExample_Success

	TestsuiteReportFail
	bra.s QuickExample_TestsComplete

QuickExample_Success:
	TestsuiteReportPass

QuickExample_TestsComplete:
