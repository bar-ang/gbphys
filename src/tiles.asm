
DEF BG_VRAM     EQU 0
DEF FLOOR_VRAM  EQU 1
DEF WALL_VRAM   EQU 2

DEF PLAYER_WALK EQU 0 ; alternating between 0, 1
DEF PLAYER_REST EQU 2
DEF PLAYER_JUMP EQU 3


SECTION "Tile data", ROM0

Objects:
INCLUDE "assets/player.asm"
        dw `11000001
        dw `01100001
        dw `00112211
        dw `00222210
        dw `00223220
        dw `01122220
        dw `11000110
        dw `10000011
EndObjects:

Tiles:
Background:
        dw `00000000
        dw `01010101
        dw `00000000
        dw `10101010
        dw `00000000
        dw `01010101
        dw `00000000
        dw `10101010
EndBackground:

FloorTiles:
        dw `00000000
        dw `00000000
        dw `00000000
        dw `11111111
        dw `21212121
        dw `23232323
        dw `33333333
        dw `33333333
EndFloorTiles:

WallTiles:
        dw `11233311
        dw `11222311
        dw `11233311
        dw `11222311
        dw `11233311
        dw `11222311
        dw `11233311
        dw `11222311
EndWallTiles:

EndTiles:

ASCII:
        INCBIN "assets/hexset.2bpp"
EndASCII:


SECTION "Tilemap", ROM0

TileMap:
        INCBIN "assets/tilemap.2bpp"
EndTileMap:
