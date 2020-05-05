	move.w	#$D1CC, d0

	cmpi.w	#$D1CC, d0
	beq.s	QuickExample_Success

	TestsuiteReportFail
	bra.s QuickExample_TestsComplete

QuickExample_Success:
	TestsuiteReportPass

QuickExample_TestsComplete:
