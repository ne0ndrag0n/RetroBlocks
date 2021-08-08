Memory Map
==========

# Main RAM

*This document describes the memory map for the game.*

| Address | Bytes | Constant Symbol                | Meaning                                     |
|---------|-------|--------------------------------|---------------------------------------------|
| FF0000  | 14    | (none)                         | Reserved                                    |
| FF000E  | 1     | VDP_VIDEO_MODE                 | Current value of VDP Register #01           |
| FF000F  | 1     | LOCK_STATUS                    | Semaphores for interrupt operations         |
| FF0010  | 2     | JOYPAD_STATE_1                 | Joypad 1 State                              |
| FF0012  | 4     | TOTAL_TICKS                    | Game Ticks                                  |
| FF0016  | 154   | (none)                         | Free/Unused                                 |
| FF00B0  | 80    | VDP_DMAQUEUE_START             | DMA Queue                                   |
| FF0100  | 7168  | HICOLOR_PALETTES               | HiColor palettes lines 0-223                |
| FF1D00  | 2240  | HICOLOR_PALETTE_CELLS          | HiColor palette cell pointers 40x28         |
| FF25C0  | 4     | HICOLOR_NEXT_LINE              | Address of next HiColor palette             |
| FF25C4  | 10812 | (none)                         | Free/Unused								 |
| FF5000  | 1024  | HEAP                           | Dynamic Memory                              |
| FF5400  | 35840 | FRAMEBUFFER                    | 320x224 4bpp Framebuffer                    |
| FFE000  | 4096  | THREAD_BACK_STACK<sup>2</sup>  | Background Thread Stack					 |
| FFF000  | 4096  | THREAD_MAIN_STACK<sup>2</sup>  | Main Thread Stack							 |

# Notes
<sup>1</sup> Priority settings in number of ticks, which will count down once per vblank. When zero, the threader will toggle the main and background thread.

<sup>2</sup> Stacks begin from the bottom-up. THREAD_MAIN_STACK is defined as $FFFC, and THREAD_BACK_STACK is defined as 4096 bytes behind.

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