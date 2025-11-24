INCLUDE "object.asm"

DEF BG_VRAM     EQU 0
DEF FLOOR_VRAM  EQU 1

DEF PLAYER_WALK EQU 0 ; alternating between 0, 1
DEF PLAYER_REST EQU 2
DEF PLAYER_JUMP EQU 3


SECTION "Tile data", ROM0
Tiles:
Background:
        dw `33333333
        dw `33333333
        dw `33333333
        dw `33322333
        dw `33122133
        dw `33333333
        dw `33333333
        dw `33333333
EndBackground:

FloorTiles:
        dw `11111111
        dw `21212121
        dw `23232323
        dw `33333333
        dw `00000000
        dw `00000000
        dw `33333333
        dw `33333333
EndFloorTiles:

EndTiles:

ASCII:
        INCBIN "hexset.2bpp"
EndASCII:


SECTION "Tilemap", ROM0

TileMap:
        INCBIN "tilemap.2bpp"
EndTileMap:
