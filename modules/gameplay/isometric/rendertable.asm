	ifnd H_RENDERTABLE
H_RENDERTABLE = 1

; Lookup table for the render algorithm
; The plane is 64x64 and the drawing pattern is the same every time
; Therefore, all you really dynamically use is an origin
; This table is a list of tile coordinates that the renderer will just rattle off
; when an update is required.

IsometricRendertable:
	; alignment null, Origin tile x, origin tile y, repeat process count

	; Iterations across
	dc.b	0, 60, 0, 1
	dc.b	0, 56, 0, 3
	dc.b	0, 52, 0, 5
	dc.b	0, 48, 0, 7
	dc.b	0, 44, 0, 9
	dc.b	0, 40, 0, 11
	dc.b	0, 36, 0, 13
	dc.b	0, 32, 0, 15
	dc.b	0, 28, 0, 17
	dc.b	0, 24, 0, 19
	dc.b	0, 20, 0, 21
	dc.b	0, 16, 0, 23
	dc.b	0, 12, 0, 25
	dc.b	0, 8, 0, 27
	dc.b	0, 4, 0, 29
	dc.b	0, 0, 0, 31

	; Iterations down
	dc.b	0, 0, 4, 29
	dc.b	0, 0, 8, 27
	dc.b	0, 0, 12, 25
	dc.b	0, 0, 16, 23
	dc.b	0, 0, 20, 21
	dc.b	0, 0, 24, 19
	dc.b	0, 0, 28, 17
	dc.b	0, 0, 32, 15
	dc.b	0, 0, 36, 13
	dc.b	0, 0, 40, 11
	dc.b	0, 0, 44, 9
	dc.b	0, 0, 48, 7
	dc.b	0, 0, 52, 5
	dc.b	0, 0, 56, 3
	dc.b	0, 0, 60, 1

IsometricRendertable_End:

	endif