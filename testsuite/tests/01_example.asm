Test1:
	move.w	#$DEAD, d0

	cmpi.w	#$DEAD, d0
	beq.s	QuickExample_Success

	TestsuiteReportFail #0
	bra.s QuickExample_TestsComplete

QuickExample_Success:
	TestsuiteReportPass #0

QuickExample_TestsComplete:
