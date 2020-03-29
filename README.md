gencordia
=========

Test of an isometric voxel game for the Sega Megadrive.

To build, install [vasm](http://sun.hasenbraten.de/vasm/) with Motorola 68000 syntax module, and then type:
```
vasmm68k_mot -spaces -Fbin main.asm -o main.bin
```

To run:
```
mame genesis -cart main.bin
```

To debug:
```
mame genesis -debug -cart main.bin
```

To print the location of a symbol when assembling, insert into code:
```
	printv (symbol)
```

Arguments in macros are indexed left-to-right.