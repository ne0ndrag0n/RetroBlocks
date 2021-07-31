default :
	vasmm68k_mot -spaces -Fbin main.asm -o out.bin

clean :
	@rm *.bin