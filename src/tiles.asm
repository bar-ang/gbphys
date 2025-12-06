
DEF BG_VRAM     EQU 0
DEF FLOOR_VRAM  EQU 1
DEF WALL_VRAM   EQU 2

DEF ENEMY_ORAM  EQU $10
; Spawn data positions
; e.g: enemy's Y position is set in [EnemySpawnData + SP_Y]
; IMPORTANT: ORDER MATTERS A LOT! it must match
;     the order in EnemiesSpawnData!
DEF SP_Y     EQU 0
DEF SP_X     EQU 1
DEF SP_TILE  EQU 2

DEF PLAYER_WALK EQU 0 ; alternating between 0, 1
DEF PLAYER_REST EQU 2
DEF PLAYER_JUMP EQU 3


SECTION "Tile data", ROM0

Objects:
INCLUDE "assets/player.asm"
EnemyTiles:
        dw `33000003
        dw `03300003
        dw `00332233
        dw `00222230
        dw `00221220
        dw `03322220
        dw `33000330
        dw `30000033
EndEnemyTiles:
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

SECTION "Data", ROM0

DEF NUM_ENEMIES EQU 5

EnemiesSpawnData:
; each enemy has 3 bytes:
; y pos, x pos (wordly, not on screen), type (tile ID), flags
        db $bf, $90, ENEMY_ORAM, 0
.single: ; used to calcute the size of each enemy
        db $c1, $11, ENEMY_ORAM, 0
        db $df, $65, ENEMY_ORAM, 0
        db $9f, $75, ENEMY_ORAM, 0
        db $5f, $70, ENEMY_ORAM, 0
EndEnemiesSpawnData:
