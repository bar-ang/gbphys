INCLUDE "hardware.inc"
INCLUDE "io.asm"
INCLUDE "common.asm"
INCLUDE "tiles.asm"
INCLUDE "printer.asm"

DEF SPAWN_X    EQU $40
DEF SPAWN_Y    EQU $66
DEF JUMP_HIGHT EQU 60

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

	ld bc, 0xcefa
	push bc
	ld bc, 0xadde
	push bc
	ld hl, sp + 0
	call LoadBytesTiles
	pop af
	pop af ;clear the stack

	ld de, Object
	ld hl, $8000
	ld bc, EndObject - Object
	call Memcpy


	ld de, TileMap
	ld hl, $9800
	ld bc, EndTileMap - TileMap
	call Memcpy

	call ClearOAM

	ld hl, _OAMRAM
	ld b, SPAWN_X
	ld c, SPAWN_Y
	ld d, 0
	ld e, 0
	call CreateObj

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %00011011
	ld [rBGP], a
	ld a, %00011011
	ld [rOBP0], a

	call InitKeys

	; init attributes
	ld a, 1
	ld [wVelocity], a
	ld a, 0
	ld [wJumper], a
	call changeStateFALL

	;moving the screen to bottom-left corner
	ld a, 111
	ld [rSCY], a
	
Process:
	call WaitVBlank
	ld a, [wFrame]
	inc a
	ld [wFrame], a

	ld a, [wMoveState]
	cp MOVE_STATE_REST
	jp z, .post_switch
	cp MOVE_STATE_FALL
	jp z, .fall
	cp MOVE_STATE_JUMP
	jp z, .jump
	jp .post_switch ; default

	.jump:
		ld a, [wJumper]
		dec a
		ld [wJumper], a
		cp a, 0
		jp nz, .fall
		ld a, 1
		ld [wVelocity], a
		call changeStateFALL
		jp .post_switch
	.fall:
		; obj fall down
		ld a, [wFrame]
		and a, 0x01
		jp nz, .post_switch

		ld hl, _OAMRAM
		ld b, 0
		ld a, [wVelocity]
		ld c, a
		call ObjTranslate
		
		call getTilePipeline
		cp a, FLOOR_VRAM
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
	
	ld a, [_OAMRAM + O_X]
	dec a
	ld [_OAMRAM + O_X], a
	.post_left:

	; Right
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, .post_right
	
	ld a, [_OAMRAM + O_X]
	inc a
	ld [_OAMRAM + O_X], a
	.post_right:


	; Up
	ld a, [wMoveState]
	cp MOVE_STATE_REST
	jp nz, .post_up

	ld a, [wNewKeys]
	and a, PADF_UP
	jp z, .post_up
	
	call changeStateJUMP
	ld a, JUMP_HIGHT
	ld [wJumper], a
	ld a, -1
	ld [wVelocity],a
	.post_up:

	; animate the player
	ld a, [wCurKeys]
	and a, PADF_LEFT | PADF_RIGHT
	jp z, .post_animate
	
	ld a, [wFrame]
	and a, 0x7
	jp nz, .post_animate
	ld a, [_OAMRAM + O_TILE]
	xor a, 1
	ld [_OAMRAM + O_TILE], a
	.post_animate:

	jp Process

getTilePipeline:
	ld hl, _OAMRAM
	call ObjGetPosition
	ld a, c
	add a, 5
	ld c, a
	call GetTilePos
	call GetTile
	ret

changeStateREST:
	ld a, MOVE_STATE_REST
	ld [wMoveState], a
	ld a, PLAYER_WALK
	ld [_OAMRAM + O_TILE], a
	ret

changeStateFALL:
	ld a, MOVE_STATE_FALL
	ld [wMoveState], a
	ret

changeStateJUMP:
	ld a, MOVE_STATE_JUMP
	ld [wMoveState], a
	ld a, PLAYER_JUMP
	ld [_OAMRAM + O_TILE], a
	ret

SECTION "Attributes", WRAM0
	wVelocity: db
	wJumper: db

	; 0 - rest
	; 1 - fall
	; 2 - jump
	wMoveState: db

SECTION "Counter", WRAM0
	wFrame: db
