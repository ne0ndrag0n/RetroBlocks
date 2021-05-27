RetroBlocks
===========

Hobby/WIP. Voxel world + triangle rasteriser tech demo for Sega Genesis. Developed using pure 68000 assembly, with some Python to generate lookup tables.

To build, install [vasm](http://sun.hasenbraten.de/vasm/) with Motorola 68000 syntax module, and then type:
```
vasmm68k_mot -spaces -Fbin main.asm -o main.bin
```

If you get a Python error, make sure you have Python 3 installed and then use pip to install the "Requests" library:
```
pip3 install requests
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