default :
	vasmm68k_mot -spaces -Fbin main.asm -o out.bin

testsuite :
	vasmm68k_mot -spaces -Fbin main.asm -o out.bin -DTESTSUITE

clean :
	rm *.bin