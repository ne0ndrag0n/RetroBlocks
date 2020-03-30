SRAM Diff Compression Format
============================

# Background
The world in Concordia is sized 255x255x255. Storing a world of this size is an obvious challenge on a 16-bit-era console like the Sega Genesis. Therefore, it is economical to store only the *changes* to a world, or "diffs". "Diffs" have the simultaneous advantage of being compressible as operations that condense multiple changes to a world into a single command, such as run-length encoded columns or volumetric flood fill.

# SRAM Size Constraints
*Concordia* is expected to fit onto a standard Sega Genesis cartridge with an appropriately-sized EEPROM for ROM data, and an 8K SRAM for save data. The diffs for a 255x255x255 world will be expected to fit inside an 8K SRAM. With creative enough compression, this can be done - but there are still corner cases where the SRAM can become saturated.

One example would be, for whatever reason, if the player diffs each chunk enough such that the distribution is truly random. This would force the engine to store the chunk changes entirely as type 00/Simple Block Replace, which would blow out the SRAM. This should be accounted for in some elegant capacity, i.e., working into the gameplay a prohibition on world changes until large structures are demolished, etc.

# Format
[ xx ] [ yy ] [ zz ] [ cc ] [ data... ]
xx/yy/zz - Positions of a change
cc - The operation to be performed, within the chunk x/y/z lies within, with the following data.
data... - The block data

## Block Operations

### 00: Simple Block Replace
Data: [ cc bb ]
cc - Block options (lower 7 bits)
bb - Block ID

Replaces the block at x, y, z with block id "bb" and state "cc". The uppermost bit of "cc" is reserved (for marking in active chunks during compression)

### 01: Run-Length Decode, X
Data: [ rr ] [ cc bb ]
rr - Run count (Up to 16 in any direction)
cc - Block options (lower 7 bits)
bb - Block ID

Replaces block at x, y, z with block id "bb" and state "cc". Then, for a count of run "rr", the operation is repeated in the X+ direction.

### 02: Run-Length Decode, Y
Data: [ rr ] [ cc bb ]
rr - Run count (Up to 16 in any direction)
cc - Block options (lower 7 bits)
bb - Block ID

Replaces block at x, y, z with block id "bb" and state "cc". Then, for a count of run "rr", the operation is repeated in the Y+ direction.

### 03: Run-Length Decode, Z
Data: [ rr ] [ cc bb ]
rr - Run count (Up to 16 in any direction)
cc - Block options (lower 7 bits)
bb - Block ID

Replaces block at x, y, z with block id "bb" and state "cc". Then, for a count of run "rr", the operation is repeated in the Z+ direction.

### 04: Flood Fill
Data: (boundary)[ cc bb ] [ cc bb ]
Boundary block and target block:
cc - Block options (lower 7 bits)
bb - Block ID

Replaces block at x, y, z with block id "bb" and state "cc". Then, initiate a volumetric flood fill of the block and state, which will apply the block diff repeatedly unless the bounary block type is encountered.

### Future operations
The possibilities here are fairly expansive and will include more compressive operations to reduce common gameplay idioms to single instructions as much as possible. For instance, sphere, cube, and cone shapes can be stored as operations. Water/lava fills, gable roofs, checkerboarded floors, spires, and trees can all be encoded as single, compact operations as well.