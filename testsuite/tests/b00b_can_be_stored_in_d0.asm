	move.w	#$B00B, d0

	cmpi.w	#$B00B, d0
	beq.s	QuickExample_Success

	TestsuiteReportFail
	bra.s QuickExample_TestsComplete

QuickExample_Success:
	TestsuiteReportPass

QuickExample_TestsComplete:
