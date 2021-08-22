Memory Map
==========

# Main RAM

*This document describes the memory map for the game.*

| Address | Bytes | Constant Symbol                | Meaning                                     |
|---------|-------|--------------------------------|---------------------------------------------|
| FF0000  | 14    | (none)                         | Reserved                                    |
| FF000E  | 1     | HICOLOR_REMAINING_COLORS       | Counter used to render Hicolor regions      |
| FF000F  | 1     | SYSTEM_STATUS                  | Options and semaphores (see below)          |
| FF0010  | 2     | JOYPAD_STATE_1                 | Joypad 1 State                              |
| FF0012  | 4     | TOTAL_TICKS                    | Game Ticks                                  |
| FF0016  | 142   | VDP_DMAQUEUE_START             | DMA Queue                                   |
| FF00A4  | 4     | HICOLOR_NEXT_HBLANK_WORD       | Control word sent every HBlank for Hicolor  |
| FF00A8  | 896   | HICOLOR_PALETTES               | Palette pairs for each Hicolor region       |
| FF0428  | 20440 | (none)                         | Free/Unused								 |
| FF5400  | 35840 | FRAMEBUFFER                    | 320x224 4bpp Framebuffer                    |
| FFE000  | 7168  | HEAP                           | Dynamic Memory            					 |
| FFFC00  | 1024  | STACK						   | Reserved for stack space                    |

## SYSTEM_STATUS flags
|	7	|	6	|	5	|	4	|	3	|		2	  	 |		1	    |		0	       |
|-------|-------|-------|-------|-------|----------------|--------------|------------------|
| None  | None  | None  | None  | None  | None           | None         | VDP_CONTROL Lock |

Bit 0: VDP_CONTROL lock. When set, vblank will not write to VDP_CONTROL.

# VRAM

## All Modes

| Address | Bytes | Meaning                |
|---------|-------|------------------------|
| 0000    | 3072  | Debug Font<sup>1</sup> |

## Tilescreen State

| Address | Bytes | Meaning                |
|---------|-------|------------------------|
| ...     | ...   | (all modes data)       |
| 0C00    | 44016 | Patterns/Art           |
| B7F0    | 16    | Sprite Metadata        |
| B800    | 640   | Sprite Attribute Table |
| BA80    | 384   | Free/Unused            |
| BC00    | 1024  | HScroll Table          |
| C000    | 4096  | Plane A Nametable      |
| D000    | 4096  | Window Nametable       |
| E000    | 4096  | Plane B Nametable      |
| F000    | 4096  | Free/Unused            |


## Framebuffer (Gameplay) State

| Address | Bytes | Meaning                |
|---------|-------|------------------------|
| ...     | ...   | (all modes data)       |
| 0C00    | 35840 | Framebuffer Data       |
| 9800    | 8176  | UI Patterns/Art        |
| B7F0    | 16    | Sprite Metadata        |
| B800    | 640   | Sprite Attribute Table |
| BA80    | 384   | Free/Unused            |
| BC00    | 1024  | HScroll Table          |
| C000    | 4096  | Plane A Nametable      |
| D000    | 4096  | Window Nametable       |
| E000    | 4096  | Plane B Nametable      |
| F000    | 4096  | Free/Unused            |


<sup>1</sup> Tiles in VRAM are indexed in 32-byte segments. The font runs from $00 to $5F using this system.