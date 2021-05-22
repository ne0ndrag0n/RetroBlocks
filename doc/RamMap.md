Memory Map
==========

# Main RAM

*This document describes the memory map for the game.*

| Address | Bytes | Constant Symbol                | Meaning                                     |
|---------|-------|--------------------------------|---------------------------------------------|
| FF0000  | 16    | (none)                         | Reserved                                    |
| FF0010  | 2     | JOYPAD_STATE_1                 | Joypad 1 State                              |
| FF0012  | 4     | TOTAL_TICKS                    | Game Ticks                                  |
| FF0016  | 1     | THREADER_MAIN_PRIORITY_SETTING | Main Thread Priority<sup>1</sup>            |
| FF0017  | 1     | THREADER_BACK_PRIORITY_SETTING | Background Thread Priority<sup>1</sup>      |
| FF0018  | 1     | THREADER_REMAINING_TICKS       | Remaining ticks of current thread           |
| FF0019  | 1     | THREADER_NEXT_CONTEXT          | Next Thread Toggle Flag                     |
| FF0020  | 72    | THREADER_MAIN_CONTEXT          | Process Control Block, Main Thread          |
| FF0068  | 72    | THREADER_BACK_CONTEXT          | Process Control Block, Background Thread    |
| FF00B0  | 80    | VDP_DMAQUEUE_START             | DMA Queue                                   |
| FF0100  | 35840 | FRAMEBUFFER                    | 320x224 4bpp Framebuffer                    |
| FF8D00  | 21247 | (none)                         | Free/Unused                                 |
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


<sup>1</sup> Tiles in VRAM are indexed in 32-byte segments. The font runs from $00 to $5F using this system.