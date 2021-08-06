  ifnd H_TITLESCREEN
H_TITLESCREEN = 1


LoadTitlescreen:
  VdpErasePlane #VDP_TITLESCREEN_PLANE_A
  VdpErasePlane #VDP_TITLESCREEN_PLANE_B

  VdpLoadPaletteDma #VDP_PAL_0, #VGAPalette
  VdpLoadPaletteDma #VDP_PAL_1, #TitlescreenPalette

  VdpLoadPatternDma #TS_FONT_LOCATION, #96,   #Font
  VdpLoadPatternDma #TS_BG_LOCATION,   #1120, #TitlescreenPattern

  VdpBlitPattern #$0000, #$281C, #TS_BG_LOCATION, #VDP_TITLESCREEN_PLANE_B, #64, #$0020 ; Draw the background

  ; Draw text items
  VdpDrawText #$0001, #VDP_TITLESCREEN_PLANE_A, #String_Concordia
  VdpDrawText #$0C02, #VDP_TITLESCREEN_PLANE_A, #String_Version
  rts

  endif
