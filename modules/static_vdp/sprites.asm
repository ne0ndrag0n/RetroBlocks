  ifnd H_SPRITES_MANAGER
H_SPRITES_MANAGER = 1

SPRITE_VERTICAL_SIZE_1=$0000
SPRITE_VERTICAL_SIZE_2=$0100
SPRITE_VERTICAL_SIZE_3=$0200
SPRITE_VERTICAL_SIZE_4=$0300

SPRITE_HORIZONTAL_SIZE_1=$0000
SPRITE_HORIZONTAL_SIZE_2=$0400
SPRITE_HORIZONTAL_SIZE_3=$0800
SPRITE_HORIZONTAL_SIZE_4=$0C00

SPRITE_PRIORITY=$8000
SPRITE_PAL_0=$0000
SPRITE_PAL_1=$2000
SPRITE_PAL_2=$4000
SPRITE_PAL_3=$6000

SPRITE_VFLIP=$1000
SPRITE_HFLIP=$0800

  macro VdpNewSprite
    move.w  \4, -(sp)
    move.w  \3, -(sp)
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr NewSprite
    PopStack 8
  endm

  macro VdpRemoveSprite
    move.w  \1, -(sp)
    jsr RemoveSprite
    PopStack 2
  endm

  macro SpriteIndexToVram
    ;(VDP_SPRITES + ( 8 * index ))
    move.w  \1, d1            ; 8 * index
    mulu.w  #8, d1
    addi.w  #VDP_SPRITES, d1  ; + VDP_SPRITES
  endm

  macro VdpSetSpritePositionX
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr SetSpritePositionX
    PopStack 4
  endm

  macro VdpSetSpritePositionY
    move.w  \2, -(sp)
    move.w  \1, -(sp)
    jsr SetSpritePositionY
    PopStack 4
  endm

; xx xx - Location of sprite, x
; yy yy - Location of sprite, y
; 00 hv - Horizontal and vertical size
; aa ii - Index of sprite pattern w/attributes
; Returns: numeric index of sprite just created in sprite attribute table - or -1 if we couldn't make one.
NewSprite:
  jsr FindNearestOpenSprite

  cmpi.w  #-1, d0
  bne.s   NewSprite_Allocate

  rts                         ; d0 is -1, so return that if we can't allocate a sprite

NewSprite_Allocate:
  move.l  d0, d1              ; Save the original return value

  mulu.w  #8, d0              ; 8 * index
  addi.w  #VDP_SPRITES, d0    ; + VDP_SPRITES

  move.l  d1, -(sp)

  move.w  #0, -(sp)           ; Vram write
  move.w  d0, -(sp)           ; VDP destination
  move.w  #0, -(sp)
  jsr ComputeVdpDestinationAddress
  PopStack 6

  move.l  (sp)+, d1

  move.l  d0, (VDP_CONTROL)   ; Set VDP to write to this address

  move.w  6(sp), d0           ; Load yy yy
  addi.w  #$80, d0            ; All locations must be + 128
  move.w  d0, (VDP_DATA)      ; Write vertical position and autoincrement

  move.w  8(sp), d0           ; Load hv size attributes
  andi.w  #$FF80, d0          ; Don't keep any potential link field provided - This is the item at the end of the list
  move.w  d0, (VDP_DATA)      ; Write hv size attributes and link and autoincrement

  move.w  10(sp), (VDP_DATA)  ; Load tile attribute data - No postprocessing required and autoincrement

  move.w  4(sp), d0           ; Load xx xx
  addi.w  #$80, d0            ; All locations must be + 128
  move.w  d0, (VDP_DATA)      ; Write horizontal position and autoincrement

  move.l  d2, -(sp)           ; Save d2 as we're about to screw with it

  move.l  d1, d2              ; Go get original return value
  lsr.l   #7, d2              ; Original end of list index is at upper word so >> 16
  lsr.l   #7, d2
  lsr.l   #2, d2

  cmpi.w  #-1, d2             ; If we don't have to write to the old value, don't
  beq.s   NewSprite_Return

  mulu.w  #8, d2              ; index * 8
  addi.w  #VDP_SPRITES, d2    ; + VDP_SPRITES
  addi.w  #2, d2              ; + 2, to get at the link attribute

  move.l  d2, -(sp)
  move.l  d1, -(sp)

  move.w  d2, -(sp)           ; Read existing vram word at previous end of list
  jsr ReadVramWord
  PopStack 2

  move.l  (sp)+, d1
  move.l  (sp)+, d2

  andi.w  #$FF80, d0          ; Clear the link attribute for good measure
  or.w    d1, d0              ; OR the latest sprite attribute table index, onto the word we just fetched

  move.l  d1, -(sp)           ; We still need d1 for the return value!

  move.w  d0, -(sp)           ; Write those contents to VRAM
  move.w  d2, -(sp)           ; At the same address we read from
  jsr WriteVramWord
  PopStack 4

  move.l  (sp)+, d1           ; Restore d1

NewSprite_Return:
  move.w  d1, d0              ; Return the index of the item we created

  move.l  (sp)+, d2           ; Slip d2 back
  rts

; Returns: The nearest open "slot" in the sprite attribute table. -1 if we're out of sprites.
; Longword - High word contains the index of the last zero item (-1 if none needs to be set). Low word contains the next item ready to use.
FindNearestOpenSprite:
  SetupFramePointer

  ; Local variables
  move.w  #0, -(sp)                ; -6(fp) = current index
  move.w  #-1, -(sp)               ; -8(fp) = Next item ready to use
  move.w  #-1, -(sp)               ; -10(fp) = Index of the last item with a zero link

FindNearestOpenSprite_Loop:
  SpriteIndexToVram -6(fp)         ; Read the tile data of the current sprite
  addi.w  #4, d1
  move.w  d1, -(sp)
  jsr ReadVramWord
  PopStack 2

  andi.w  #$07FF, d0              ; Only keep the tile data
  tst.w   d0                      ; Zero signifies free sprite
  beq.s   FindNearestOpenSprite_Found

  SpriteIndexToVram -6(fp)        ; Read the link data of item that wasn't free
  addi.w  #2, d1
  move.w  d1, -(sp)
  jsr ReadVramWord
  PopStack 2

  andi.w  #$007F, d0              ; This will be the next item read
  tst.w   d0                      ; Break infinite loop if we're going back to 0
  beq.s   FindNearestOpenSprite_NotFound

  move.w  d0, -6(fp)              ; Save link as next index
  bra.s   FindNearestOpenSprite_Loop

FindNearestOpenSprite_NotFound:
  move.w  -6(fp), -10(fp)         ; Save previous item

  addi.w  #1, -6(fp)              ; Increment current position
  cmpi.w  #80, -6(fp)             ; Out of sprites if -6(fp) is 80 or higher
  blo.s   FindNearestOpenSprite_Found

  move.w  #-1, -6(fp)             ; No item available

FindNearestOpenSprite_Found:
  move.w  -6(fp), -8(fp)          ; Move current index to result index
                                  ; The previous index was saved in the previous iteration

FindNearestOpenSprite_Return:
  move.l  -10(fp), d0              ; Prepare to return results

  PopStack 6
  RestoreFramePointer
  rts

; 00 ii - Sprite ID
; Returns: X position of sprite
GetSpritePositionX:
  SpriteIndexToVram   4(sp)
  addi.w  #6, d1

  move.w  d1, -(sp)
  jsr ReadVramWord
  PopStack 2

  subi.w  #$80, d0
  rts

; 00 ii - Sprite ID
; Returns: Y position of sprite
GetSpritePositionY:
  SpriteIndexToVram    4(sp)

  move.w  d1, -(sp)
  jsr ReadVramWord
  PopStack 2

  subi.w  #$80, d0
  rts

; 00 ii - Sprite ID
; xx xx - New X position of sprite
SetSpritePositionX:
  SpriteIndexToVram     4(sp)
  addi.w  #6, d1

  move.w  6(sp), d0
  addi.w  #$80, d0
  move.w  d0, 6(sp)

  move.w  6(sp), -(sp)
  move.w  d1, -(sp)
  jsr WriteVramWord
  PopStack 4
  rts

; 00 ii - Sprite ID
; yy yy - New Y position of sprite
SetSpritePositionY:
  SpriteIndexToVram     4(sp)

  move.w  6(sp), d0
  addi.w  #$80, d0
  move.w  d0, 6(sp)

  move.w  6(sp), -(sp)
  move.w  d1, -(sp)
  jsr WriteVramWord
  PopStack 4
  rts

; 00 ii - Sprite ID
; Returns: Attrib settings for given sprite
GetSpriteSizeAttrib:
  SpriteIndexToVram   4(sp)
  addi.w  #2, d1

  move.w  d1, -(sp)
  jsr ReadVramWord
  PopStack 2

  andi.w  #$FF80, d0  ; Discard link attribute - it's none of your business!
  rts

; 00 ii - Sprite ID
; dd dd - New sprite flip attributes
SetSpriteSizeAttrib:
  move.w  6(sp), d0   ; You can't overwrite the link data, so sanitize this away
  andi.w  #$FF80, d0
  move.w  d0, 6(sp)

  SpriteIndexToVram   4(sp)
  addi.w  #2, d1

  move.l  d1, -(sp)   ; ReadVramWord may corrupt d1

  move.w  d1, -(sp)   ; Get the original one to preserve its link data
  jsr ReadVramWord
  PopStack 2

  move.l  (sp)+, d1   ; Restore d1

  andi.w  #$007F, d0  ; Keep the link data we just fetched
  or.w    d0, 6(sp)   ; Paint the existing link data on top of the new flip attrs

  move.w  6(sp), -(sp)  ; Do vram write
  move.w  d1, -(sp)
  jsr WriteVramWord
  PopStack 4
  rts

; 00 ii - Sprite ID
; Returns: Tile attrib for given sprite
GetSpriteTileAttrib:
  SpriteIndexToVram   4(sp)
  addi.w  #4, d1

  move.w  d1, -(sp)
  jsr ReadVramWord
  PopStack 2
  rts

; 00 ii - Sprite ID
; dd dd - New sprite tile attributes
SetSpriteTileAttrib:
  SpriteIndexToVram   4(sp)
  addi.w  #4, d1

  move.w  6(sp), -(sp)
  move.w  d1, -(sp)
  jsr WriteVramWord
  PopStack 4
  rts

; 4(fp) - 00 ii - Sprite id
RemoveSprite:
  SetupFramePointer

  SpriteIndexToVram 4(fp)
  move.w  d1, -(sp)           ; -6(fp) = Base address of target

  addi.w  #2, d1              ; Read the link + hv size
  move.w  d1, -(sp)
  jsr ReadVramWord
  PopStack 2

  andi.w  #$007F, d0          ; Keep only the link attribute

  move.w  -6(fp), d1          ; Write the value back
  addi.w  #2, d1
  move.w  d0, -(sp)
  move.w  d1, -(sp)
  jsr WriteVramWord
  PopStack 4

  move.w  -6(fp), d1          ; Zero out the sprite attr
  addi.w  #4, d1
  move.w  #0, -(sp)
  move.w  d1, -(sp)
  jsr WriteVramWord
  PopStack 4

  PopStack 2
  RestoreFramePointer
  rts

  endif
