default : #intdiv8_tbl
	vasmm68k_mot -spaces -Fbin main.asm -o out.bin

#intdiv8_tbl :
#	@data/tables/generate_intdiv8.py modules/framebuffer/constants.asm data/tables/intdiv8.tbl

clean :
#	@rm data/tables/*.tbl
	@rm *.bin