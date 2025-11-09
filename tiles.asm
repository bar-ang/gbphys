
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

Object:
        ; rest
        dw `00111100
        dw `01222210
        dw `13222231
        dw `12322321
        dw `13222231
        dw `12322321
        dw `01222210
        dw `00111100

        ; move left-right I
        dw `00211200
        dw `01222210
        dw `13222231
        dw `12311321
        dw `13211231
        dw `12322321
        dw `01222210
        dw `00211200
        dw `00211200

        ; move left-right II
        dw `01222210
        dw `13222231
        dw `12333321
        dw `13233231
        dw `12322321
        dw `01222210
        dw `00211200
EndObject:
