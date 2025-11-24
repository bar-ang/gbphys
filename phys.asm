INCLUDE "hardware.inc"
INCLUDE "io.asm"
INCLUDE "common.asm"
INCLUDE "tiles.asm"
INCLUDE "printer.asm"
INCLUDE "pseudo_math.asm"

DEF SPAWN_X    EQU $40
DEF SPAWN_Y    EQU $d0

DEF MOVE_STATE_REST EQU 0
DEF MOVE_STATE_FALL EQU 1
DEF MOVE_STATE_JUMP EQU 2

DEF O_Y     EQU 0
DEF O_X     EQU 1
DEF O_TILE  EQU 2
DEF O_FLAGS EQU 3

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

	ld de, Object
	ld hl, $8000
	ld bc, EndObject - Object
	call Memcpy


	ld de, TileMap
	ld hl, $9800
	ld bc, EndTileMap - TileMap
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

	ld a, SPAWN_X
	ld [Player + O_X], a
	ld a, SPAWN_Y
	ld [Player + O_Y], a
	ld a, 0
	ld [Player + O_TILE], a
	ld [Player + O_FLAGS], a
	

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

	call changeStateFALL

	;moving the screen to bottom-left corner
	ld a, 0
	ld [rSCX], a
	ld a, 111
	ld [rSCY], a
	
Process:
	call WaitVBlank
	ld a, [wFrame]
	inc a
	ld [wFrame], a

	ld a, [wMoveState]
	cp MOVE_STATE_REST
	jp z, .rest
	cp MOVE_STATE_FALL
	jp z, .fall
	cp MOVE_STATE_JUMP
	jp z, .jump
	jp .post_switch ; default

	.rest:
		; if there's no floor below, change to FALL
		call TestFloorCollision
		jp z, .post_switch
		call changeStateFALL
		jp .post_switch
	.jump:
		ld a, [wJumper]
		dec a
		ld [wJumper], a
		cp a, 0
		jp nz, .cont
		call changeStateREST
		jp .post_switch
		
		.cont:
		ld hl, JumpFunc
		ld a, [wJumper]
		ld c, a
		ld b, 0
		add hl, bc
		ld a, [hl]
		ld b, a
		ld a, [Player + O_Y]
		sub a, b
		ld [Player + O_Y], a

		ld a, c; note that c == [wJumper]
		cp a, 45
		jp c, .hit_ground_test
		jp .post_switch
	.fall:
		; obj fall down
		ld a, [wFrame]
		and a, 0x01
		jp nz, .post_switch

		ld hl, Player
		ld b, 0
		ld a, 1
		ld c, a
		call PlayerTranslate

	.hit_ground_test:
		call TestFloorCollision
		jp nz, .post_switch

		; switch to REST if hitting the ground
		call changeStateREST
		
		jp .post_switch
	.post_switch:
	; handle keyboard input
	call UpdateKeys

	; Left
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, .post_left
	
	ld a, [Player + O_X]
	dec a
	ld [Player + O_X], a

	ld a, [wNewKeys]
	and a, PADF_LEFT
	jp z, .post_left
	ld a, [Player + O_FLAGS]
	or a, 0x20
	ld [Player + O_FLAGS], a
	.post_left:

	; Right
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, .post_right
	
	ld a, [Player + O_X]
	inc a
	ld [Player + O_X], a
	
	ld a, [wNewKeys]
	and a, PADF_RIGHT
	jp z, .post_right
	ld a, [Player + O_FLAGS]
	and a, 0xDF
	ld [Player + O_FLAGS], a
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
	ld [Player + O_TILE], a
	.post_animate:

	call adjustScreenPos
	call UpdateOAM

	;debug printing
	ld hl, Player
	call LoadBytesTiles

	jp Process

adjustScreenPos:
	ld a, [Player + O_X]
	sub a, 80
	jp nc, .no_edge_left
	ld a, 0
	.no_edge_left:
	cp a, 96
	jp c, .no_edge_right
	ld a, 95
	.no_edge_right:
	ld [rSCX], a
	
	ld a, [Player + O_Y]
	sub a, 108
	jp nc, .no_edge_top
	ld a, 0
	.no_edge_top:
	cp a, 112
	jp c, .no_edge_bottom
	ld a, 111
	.no_edge_bottom:
	ld [rSCY], a
	ret

TestFloorCollision:
	ld hl, Player
	ld a, [Player + O_X]
	add a, 8
	ld b, a
	ld a, [Player + O_Y]
	add a, 8
	ld c, a
	call GetTilePos
	call GetTile
	cp a, FLOOR_VRAM
	ret

changeStateREST:
	ld a, MOVE_STATE_REST
	ld [wMoveState], a
	ld a, PLAYER_WALK
	ld [Player + O_TILE], a
	ret

changeStateFALL:
	ld a, MOVE_STATE_FALL
	ld [wMoveState], a
	ret

changeStateJUMP:
	ld a, MOVE_STATE_JUMP
	ld [wMoveState], a
	ld a, PLAYER_JUMP
	ld [Player + O_TILE], a
	ld a, JUMP_DURATION + 1
	ld [wJumper], a
	ret

UpdateOAM:
; TODO: a macro for preventing code dup would be nice.

; BOTTOM LEFT
	ld hl, _OAMRAM
	ld a, [Player + O_FLAGS]
	and a, 0x20
	swap a
	sla a
	sla a
	ld e, a ; now e contains 8 if object is flipped or 0 otherwise
	; e will be used all throughout 'UpdateOAM' so don't override it!
	
	; Y coord = player.Y - SCY
	ld a, [rSCY]
	ld b, a
	ld a, [Player + O_Y]
	sub a, b
	add a, Y_OFFSET
	ld [hli], a
	; X coord = player.X - SCX
	ld a, [rSCX]
	ld b, a
	ld a, [Player + O_X]
	sub a, b
	add a, e
	add a, X_OFFSET
	
	ld [hli], a
	; Tile ID
	ld a, [Player + O_TILE]
	add a, 8
	ld [hli], a
	;Flags
	ld a, [Player + O_FLAGS]
	ld [hli], a


; BOTTOM RIGHT
	ld hl, _OAMRAM + 4
	; Y coord = player.Y - SCY
	ld a, [rSCY]
	ld b, a
	ld a, [Player + O_Y]
	sub a, b
	add a, Y_OFFSET
	ld [hli], a
	; X coord = player.X - SCX
	ld a, [rSCX]
	ld b, a
	ld a, [Player + O_X]
	sub a, b
	add a, X_OFFSET
	add a, 8
	sub a, e
	ld [hli], a
	; Tile ID
	ld a, [Player + O_TILE]
	add a, 12
	ld [hli], a
	;Flags
	ld a, [Player + O_FLAGS]
	ld [hli], a


; UPPER LEFT
	ld hl, _OAMRAM + 8
	; Y coord = player.Y - SCY
	ld a, [rSCY]
	ld b, a
	ld a, [Player + O_Y]
	sub a, b
	add a, Y_OFFSET
	sub a, 8
	ld [hli], a
	; X coord = player.X - SCX
	ld a, [rSCX]
	ld b, a
	ld a, [Player + O_X]
	sub a, b
	add a, X_OFFSET
	add a, e
	ld [hli], a
	; Tile ID
	ld a, [Player + O_TILE]
	ld [hli], a
	;Flags
	ld a, [Player + O_FLAGS]
	ld [hli], a

;UPPER RIGHT
	ld hl, _OAMRAM + 12
	; Y coord = player.Y - SCY
	ld a, [rSCY]
	ld b, a
	ld a, [Player + O_Y]
	sub a, b
	add a, Y_OFFSET
	sub a, 8
	ld [hli], a
	; X coord = player.X - SCX
	ld a, [rSCX]
	ld b, a
	ld a, [Player + O_X]
	sub a, b
	add a, X_OFFSET
	add a, 8
	sub a, e
	ld [hli], a
	; Tile ID
	ld a, [Player + O_TILE]
	add a, 4
	ld [hli], a
	;Flags
	ld a, [Player + O_FLAGS]
	ld [hli], a
	
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
	wJumper: db

	; 0 - rest
	; 1 - fall
	; 2 - jump
	wMoveState: db

SECTION "Counter", WRAM0
	wFrame: db
