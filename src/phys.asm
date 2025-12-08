INCLUDE "src/hardware.inc"
INCLUDE "src/io.asm"
INCLUDE "src/common.asm"
INCLUDE "src/tiles.asm"
INCLUDE "src/printer.asm"
INCLUDE "assets/pseudo_math.asm"

DEF SPAWN_X    EQU $40
DEF SPAWN_Y    EQU $d0

DEF MOVE_STATE_REST  EQU 0
DEF MOVE_STATE_JUMP  EQU 1
DEF MOVE_STATE_DYING EQU 2
DEF MOVE_STATE_DEAD  EQU 3

DEF O_Y     EQU 0
DEF O_X     EQU 1
DEF O_TILE  EQU 2
DEF O_FLAGS EQU 3


MACRO set_player
	ld [Player + \1], a
	ld e, a
	ld a, [wOAMupdateRequired]
	or a, 1
	ld [wOAMupdateRequired], a
	ld a, e
	
ENDM

MACRO jump_math
		ld a, [wJumpMath]
		inc a
		ld [wJumpMath], a
		ld hl, PseudoParabola
		ld a, [wJumpMath]
		ld c, a
		ld b, 0
		add hl, bc
		ld a, [hl]
		ld b, a
		ld a, [Player + O_Y]
		sub a, b
		set_player O_Y

		ld a, c; note that c == [wJumpMath]
		cp a, PseudoParabola.maximum - PseudoParabola
		jp c, \1

		; switch to REST if hitting the ground
		call TestFloorCollision
		jp nz, \1

ENDM

SECTION "Header", ROM0[$100]
	jp Init
	ds $150 - @, 0 ; Make room for the header

Init:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

        call WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

        ld de, Tiles
        ld hl, $9000
        ld bc, EndTiles - Tiles
        call Memcpy

	ld de, Objects
	ld hl, $8000
	ld bc, EndObjects - Objects
	call Memcpy


	ld de, EndTileMap - $400
	ld hl, $9800
	ld bc, $400
	call Memcpy


	ld b, NUMERAL_SIZE
	ld d, -128
	ld hl, 0x9c00
	.loop:
		ld a, d
		ld [hli], a
		inc d
		dec b
		ld a, b
		cp a, 0
		jp nz, .loop


	call ClearOAM
	call ClearWorkDMA
	dma_to_hram

	ld a, SPAWN_X
	ld [Player + O_X], a
	ld a, SPAWN_Y
	ld [Player + O_Y], a
	ld a, 0
	ld [Player + O_TILE], a
	ld [Player + O_FLAGS], a

	;spawn enemies
	ld b, NUM_ENEMIES
	ld hl, EnemiesSpawnData
	ld de, Enemies
	.loop_spawn_enemies:
		REPT 4
		ld a, [hli]
		ld [de], a
		inc de
		ENDR
		
		dec b
		ld a, b
		cp a, 0
		jp nz, .loop_spawn_enemies

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_WINON | LCDCF_WIN9C00
	ld [rLCDC], a

	ld a, 167 - 8 * NUMERAL_SIZE
	ld [rWX], a
	ld a, 144-8
	ld [rWY], a

	; During the first (blank) frame, initialize display registers
	ld a, %00011011
	ld [rBGP], a
	ld a, %00011110
	ld [rOBP0], a

	call InitKeys

	call StartFalling

	;moving the screen to bottom-left corner
	ld a, 0
	ld [rSCX], a
	ld a, 111
	ld [rSCY], a

	ld a, 0
	ld [wEnemyMath], a

	xor a, a; TODO: need to set the bottom of the map
	ld [wWorldPos], a
	ld [wScreenPos], a
	
Process:
	call adjustScreenPos
	call WaitVBlank
	ld a, [wFrame]
	inc a
	ld [wFrame], a

	ld a, 2
	ld [wOAMupdateRequired], a

	ld a, [wMoveState]
	cp MOVE_STATE_REST
	jp z, .rest
	cp MOVE_STATE_JUMP
	jp z, .jump
	cp MOVE_STATE_DYING
	jp z, .dying
	jp .post_switch ; default

	.rest:
		; if there's no floor below, fall
		call TestFloorCollision
		jp z, .post_switch
		call StartFalling
		jp .post_switch
	.jump:
		jump_math .post_switch
		; 'jump_math' will jump to .post_switch unless hitting the ground
		call changeStateREST
		jp .post_switch
	.dying:
		jump_math .post_switch
		call changeStateDEAD
	.post_switch:

	; making the enemies move

	; move on X axis
	DEF i = 0
	REPT NUM_ENEMIES
		ld a, [wEnemyMath]
		ld hl, PseudoSine
		ld c, a
		ld b, 0
		add hl, bc
		ld a, [hl]
		ld b, a
		ld a, [Enemies + 4 * i + O_X]
		add a, b
		ld [Enemies + 4 * i + O_X], a

		; move on Y axis
		ld a, [wEnemyMath]
		ld hl, PseudoCosine
		ld c, a
		ld b, 0
		add hl, bc
		ld a, [hl]
		ld b, a
		ld a, [Enemies + 4 * i + O_Y]
		add a, b
		ld [Enemies + 4 * i + O_Y], a

		DEF i += 1
	ENDR

	ld a, [wEnemyMath]
	inc a
	cp a, EndPseudoSine - PseudoSine
	jp nz, .no_reset_enemy_move
	xor a, a
	.no_reset_enemy_move:
	ld [wEnemyMath], a

	call TestEnemyCollision
	cp a, $ff
	jp z, .still_alive
	call changeStateDYING
	.still_alive:
	
	; handle keyboard input
	call UpdateKeys

	ld a, [wMoveState]
	cp a, MOVE_STATE_DEAD
	jp z, .post_animate


	; DEBUG: screen move
	ld a, [wCurKeys]
	and a, PADF_A
	jp z, .post_a
	ld a, [wWorldPos]
	inc a
	ld [wWorldPos], a
	.post_a:
	
	ld a, [wCurKeys]
	and a, PADF_B
	jp z, .post_b
	ld a, [wScreenPos]
	inc a
	ld [wScreenPos], a
	.post_b:

	; Left
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, .post_left

	; if there's a wall, don't move
	call TestWallCollisionGoingLeft
	jp z, .post_left
	
	ld a, [Player + O_X]
	dec a
	set_player O_X

	ld a, [wNewKeys]
	and a, PADF_LEFT
	jp z, .post_left
	ld a, [Player + O_FLAGS]
	or a, 0x20
	set_player O_FLAGS
	.post_left:

	; Right
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, .post_right

	; if there's a wall, don't move
	call TestWallCollisionGoingRight
	jp z, .post_right
	
	ld a, [Player + O_X]
	inc a
	set_player O_X
	
	ld a, [wNewKeys]
	and a, PADF_RIGHT
	jp z, .post_right
	ld a, [Player + O_FLAGS]
	and a, 0xDF
	set_player O_FLAGS
	.post_right:


	; Up
	ld a, [wMoveState]
	cp MOVE_STATE_REST
	jp nz, .post_up

	ld a, [wNewKeys]
	and a, PADF_UP
	jp z, .post_up
	
	call changeStateJUMP
	.post_up:

	; animate the player
	ld a, [wCurKeys]
	and a, PADF_LEFT | PADF_RIGHT
	jp z, .post_animate
	
	ld a, [wFrame]
	and a, 0x7
	jp nz, .post_animate
	ld a, [Player + O_TILE]
	xor a, 1
	set_player O_TILE
	.post_animate:

	
	
	ld a, [wOAMupdateRequired]
	and a, 1
	jp z, .player_no_oam_update
	call UpdatePlayerOAM
	.player_no_oam_update:
	
	
	ld a, [wOAMupdateRequired]
	and a, 2
	jp z, .enemy_no_oam_update
	call UpdateEnemiesOAM
	.enemy_no_oam_update:

	
	; call RunHDMA
		
	;debug printing
	ld hl, wWorldPos
	call LoadBytesTiles

	jp Process

adjustScreenPos:
	; TODO: let's begin with an inefficient method:
	ld hl, TileMap
	ld a, [wWorldPos]
	ld c, a
	shift5 ; bc = (wWorldPos << 5)
	add hl, bc
	ld d, h
	ld e, l
	ld hl, $9800
	ld bc, $400
	call Memcpy

	ld a, [wScreenPos]
	ld [rSCY], a

	ret

; @return: set in A the enemy address (with 'Enemies' subtracted to save 1 byte)
;      if no collision then set: A=$ff
TestEnemyCollision:
	DEF i = 0
	REPT NUM_ENEMIES
		; NOTE: enemy size: 8x8, player size: 16x16
		ld a, [Enemies + 4*i + O_X]
		ld b, a
		ld a, [Player + O_X]

		add a, 8 + 4
		cp a, b
		jp c, .no_collision\@

		sub a, 16 + 4
		cp a, b
		jp nc, .no_collision\@

		ld a, [Enemies + 4*i + O_Y]
		ld b, a
		ld a, [Player + O_Y]

		add a, 8 - 8
		cp a, b
		jp c, .no_collision\@

		sub a, 16
		cp a, b
		jp nc, .no_collision\@

		ld a, 4*i
		ret
		
		.no_collision\@:
		DEF i+=1
	ENDR

	ld a, $ff
	ret

TestFloorCollision:
	ld hl, Player
	ld a, [Player + O_X]
	add a, 8
	ld b, a
	ld a, [Player + O_Y]
	add a, 5
	ld c, a
	call GetTilePos
	call GetTile
	cp a, FLOOR_VRAM
	ret

TestWallCollisionGoingLeft:
	ld hl, Player
	ld a, [Player + O_X]
	sub a, 1
	ld b, a
	ld a, [Player + O_Y]
	ld c, a
	call GetTilePos
	call GetTile
	cp a, WALL_VRAM
	ret

TestWallCollisionGoingRight:
	ld hl, Player
	ld a, [Player + O_X]
	add a, 16
	ld b, a
	ld a, [Player + O_Y]
	ld c, a
	call GetTilePos
	call GetTile
	cp a, WALL_VRAM
	ret

changeStateREST:
	ld a, MOVE_STATE_REST
	ld [wMoveState], a
	ld a, PLAYER_WALK
	ld [Player + O_TILE], a
	ret

StartFalling:
	ld a, MOVE_STATE_JUMP
	ld [wMoveState], a
	ld a, PLAYER_JUMP
	set_player O_TILE
	ld a, PseudoParabola.maximum - PseudoParabola + 4
	ld [wJumpMath], a
	ret

changeStateJUMP:
	ld a, MOVE_STATE_JUMP
	ld [wMoveState], a
	ld a, PLAYER_JUMP
	set_player O_TILE
	ld a, 0
	ld [wJumpMath], a
	ret

changeStateDYING:
	ld a, MOVE_STATE_DYING
	ld [wMoveState], a
	ld a, PLAYER_WALK
	ld [Player + O_TILE], a
	ld a, [Player + O_FLAGS]
	or a, $40
	set_player O_FLAGS
	ld a, PseudoParabola.maximum - PseudoParabola + 4
	ld [wJumpMath], a
	ret

changeStateDEAD:
	ld a, MOVE_STATE_DEAD
	ld [wMoveState], a
	ret

UpdatePlayerOAM:
	ld hl, wDMA
	ld a, [Player + O_FLAGS]
	and a, 0x20
	swap a
	sla a
	sla a
	ld e, a ; now e contains 8 if object is flipped vertically or 0 otherwise
	; e will be used all throughout 'UpdateOAM' so don't override it!

	ld a, [Player + O_FLAGS]
	and a, 0x40
	swap a
	sla a
	ld d, a ; now d contains 8 if object is flipped horizontally or 0 otherwise
	; d will be used all throughout 'UpdateOAM' so don't override it!

	DEF i = 0
	REPT 4	
		ld hl, wDMA + i*4
		; Y coord = player.Y - SCY
		ld a, [rSCY]
		ld b, a
		ld a, [Player + O_Y]
		sub a, b
		add a, Y_OFFSET
		sub a, 8*(i / 2)
		IF i / 2 == 0
			sub a, d
		ELSE
			add a, d
		ENDC
		ld [hli], a
		; X coord = player.X - SCX
		ld a, [Player + O_X]
		add a, X_OFFSET
		add a, 8*(i % 2)
		IF i % 2 == 0
			add a, e
		ELSE
			sub a, e
		ENDC
		ld [hli], a
		; Tile ID
		ld a, [Player + O_TILE]
		IF i == 0
			add a, 8
		ELIF i == 1
			add a, 12
		ELIF i == 2
		 	add a, 0
		ELIF i == 3
			add a, 4
		ENDC
			
		ld [hli], a
		;Flags
		ld a, [Player + O_FLAGS]
		ld [hli], a
		

	DEF i += 1
	ENDR
	ret

UpdateEnemiesOAM:
	DEF i = 0
	REPT NUM_ENEMIES
		ld hl, wDMA + 16 + 4 * i
		ld a, [rSCY]
		ld b, a
		ld a, [Enemies + 4 * i + O_Y]
		add a, Y_OFFSET
		sub a, b
		ld [hli], a

		ld a, [Enemies + 4 * i + O_X]
		add a, X_OFFSET
		ld [hli], a
		ld a, [Enemies + 4 * i + O_TILE]
		ld [hli], a
		ld a, [Enemies + 4 * i + O_FLAGS]
		ld [hli], a

		DEF i += 1
	ENDR
	ret

PlayerTranslate:
	ld a, [Player + O_X]
	add a, b
	ld [Player + O_X], a
	ld a, [Player + O_Y]
	add a, c
	ld [Player + O_Y], a
	ret

SECTION "Attributes", WRAM0
	Player: ds 4
	Enemies: ds (EndEnemiesSpawnData - EnemiesSpawnData)
	wJumpMath: db
	wEnemyMath: db
	wWorldPos: db
	wScreenPos: db ;TODO: Eventually this will probably be identical to SCY.
		;but I leave it that way for now for debugging purposes
	
	; this byte will use as a collection of 1-byte flags:
	; bit 0 - indicates if the player OAM should be updated
	; bit 1 - indicates if the enemies OAM shoud be updated
	wOAMupdateRequired: db

	; 0 - rest
	; 1 - jump
	; 2 - dead
	wMoveState: db


SECTION "Counter", WRAM0
	wFrame: db
