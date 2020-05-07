
	bra		TestInitHashtables

	; Example palette data
	dc.w	$0000, $0111, $0222, $0333, $0444, $0555, $0666, $0777
	dc.w	$0888, $0999, $0AAA, $0BBB, $0CCC, $0DDD, $0EEE, $0FFF

	dc.w	$0000, $0011, $0022, $0033, $0044, $0055, $0066, $0077
	dc.w	$0088, $0099, $00AA, $00BB, $00CC, $00DD, $00EE, $00FF

	dc.w	$0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007
	dc.w	$0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F

String_TileIncorrect:
	dc.b	'RAM tile table not correctly initialized.',10,0

TestInitHashtables:
	jsr		InitHashtables

	; Verify RAM boundary not exceeded
VerifyTileBoundary:
	move.l	#ISOBLENDER_TILE_HASHTABLE, a0
	move.w	#( (ISOBLENDER_TILE_HASHTABLE_BUCKET_SIZE*255) / 2 ) - 1, d0
VerifyTileBoundary_Loop:
	move.w	(a0), d1
	cmpi.w	#$FFFF, d1
	beq.s 	VerifyPaletteBoundary

	;TestsuitePrint String_TileIncorrect
	TestsuiteReportFail
	TestsuiteEmulatorExit

VerifyPaletteBoundary:
	TestsuiteReportPass