#!/usr/bin/python3
import sys
import re

print( "generate_intdiv8.py (cc) BY-NC 4.0 2021 Ashley N. (ne0ndrag0n)" )
print( "This utility generates a lookup table used by the framebuffer.")

# Process @framebuffer_location from sys.argv[ 1 ]
framebuffer_location = 0
with open( sys.argv[ 1 ], "r" ) as file:
        lines = file.read().splitlines()
        for line in lines:
                if "@framebuffer_location" in line:
                        framebuffer_location = int( re.findall( "\$[0-9a-fA-F]+", line )[ 0 ].replace( '$', '' ), 16 )
                        break

if framebuffer_location == 0:
        sys.exit( "@framebuffer_location annotation not found or invalid in given file." )

# Shear off top bits so that the values are only stored as 16-bit
framebuffer_location = framebuffer_location & 0x0000FFFF

array = bytearray( 320 * 224 * 2 )
for y in range( 0, 224 ):
     for x in range( 0, 320 ):
             x_cell = int( x / 8 )
             x_in_cell = x % 8

             y_cell = int( y / 8 )
             y_in_cell = y % 8

             # 1280 bytes = 32 bytes per cell * 40 cells per row
             cell_addr = ( 1280 * y_cell ) + ( 32 * x_cell )

             # cell_addr now points to top of cell. Use remainders to get the position in the cell
             # Start with y position - Move 4 bytes down for every y in the cell
             cell_addr += 4 * y_in_cell

             # Selection of X byte using x_in_cell:
             # 0, 1 - Byte 0
             # 2, 3 - Byte 1
             # 4, 5 - Byte 2
             # 6, 7 - Byte 3
             # Simple integer divide of x_in_cell by 2
             cell_addr += int( x_in_cell ) / 2

             position = ( y * 640 ) + ( x * 2 )
             addr = int( framebuffer_location + cell_addr )
             array[ position ] = ( 0x0000FF00 & addr ) >> 8
             array[ position + 1 ] = 0x000000FF & addr

with open( sys.argv[ 2 ], "wb" ) as file:
	file.write( array )

print( "intdiv8.tbl generated." )
print( "" )