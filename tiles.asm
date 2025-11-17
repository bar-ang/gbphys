DEF BG_VRAM     EQU 0
DEF FLOOR_VRAM  EQU 1

DEF PLAYER_WALK EQU 0 ; alternating between 0, 1
DEF PLAYER_REST EQU 2
DEF PLAYER_JUMP EQU 3


SECTION "Tile data", ROM0
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

EndTiles:

ASCII:
        INCBIN "hexset.2bpp"
EndASCII:

Object:
        ; move left-right I
        dw `00033300
        dw `00333330
        dw `03312333
        dw `03111333
        dw `03333333
        dw `03133000
        dw `00313300
        dw `03113300


        ; move left-right II
        dw `00033300
        dw `00333330
        dw `03312333
        dw `03111333
        dw `03333333
        dw `00331300
        dw `00313300
        dw `00013300

        ; rest
        dw `00033300
        dw `00333330
        dw `03312333
        dw `03111333
        dw `03333333
        dw `00313300
        dw `00313300
        dw `00313300

        ; Jump
        dw `00033300
        dw `00333330
        dw `03312333
        dw `03111333
        dw `00333300
        dw `00013300
        dw `00013300
        dw `00033300


EndObject:

SECTION "Tilemap", ROM0

TileMap:
        INCBIN "tilemap2.2bpp"
EndTileMap:
