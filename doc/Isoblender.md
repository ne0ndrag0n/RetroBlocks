Isoblender
==========

# Overview
The `isoblender` module is responsible for rendering the game world and placing tiles onto the destination plane. Because of the nature of isometric boards, tiles need to be blended onto one another while being rendered - the `isoblender` does this.

## Core Concepts

* Tiles are loaded from ROM, but *new* tiles are generated based on the colours they require and use at any given location.
* Palettes 1-3 with colours 1-15 are filled beginning with the tiles that need the fewest colours.

## Planes
* The plane that the world renders to is 64x64 tiles total.
* Each tile is 32x32 pixels, or 4x4 tiles.
