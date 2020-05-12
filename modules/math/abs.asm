	ifnd H_MATH_ABS
H_MATH_ABS = 1

	macro MathAbs
		tst.w	\1
		bpl.s	Positive\@
		neg.w	\1
	Positive\@:
	endm

	endif