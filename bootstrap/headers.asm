  dc.b	'SEGA GENESIS    '	; console name
  dc.b	'(C)ASHN 2020.APR'			; copyright
  dc.b	'Concordia - The World of Harmony                ' ; cart name
  dc.b	'Concordia - The World of Harmony                ' ; cart name (alt)
  dc.b	'GM 20180701-00'	; program type / serial number / version
  dc.w	$0000				; ROM checksum
  dc.b	'J               '	; I/O device support (unused)
  dc.l	$00000000			; address of ROM start
  dc.l	RomEnd				; address of ROM end
  dc.l	$00FF0000,$00FFFFFF	; RAM start/end
  dc.b	'RA',$F8,$20  		; backup RAM info (16-bit addressing, write)
  dc.l  $200001
  dc.l  $20FFFF
  dc.b	'            '		; modem info
  dc.b	'                                        ' ; comment
  dc.b	'JUE             '	; regions allowed
