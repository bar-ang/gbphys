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

	ld bc, 0xefcd
	push bc
	ld bc, 0xab89
	push bc
	ld bc, 0x6745
	push bc
	ld bc, 0x2301
	push bc
	ld hl, sp + 0
	call LoadBytesTiles
	pop af
	pop af
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
	ld [Player + 0], a
	ld a, SPAWN_Y
	ld [Player + 1], a
	ld a, 0
	ld [Player + 2], a
	ld [Player + 3], a
	

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

		ld hl, Player
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
	
	ld a, [Player + O_X]
	dec a
	ld [Player + O_X], a
	.post_left:

	; Right
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, .post_right
	
	ld a, [Player + O_X]
	inc a
	ld [Player + O_X], a
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
	ld a, [Player + O_TILE]
	xor a, 1
	ld [Player + O_TILE], a
	.post_animate:

	; ;debug printing
	; ld hl, Player
	; call LoadBytesTiles

	call UpdateOAM

	jp Process

getTilePipeline:
	ld hl, Player
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
	ret

UpdateOAM:
	ld hl, _OAMRAM
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
	ld [hli], a
	; Tile ID
	ld a, [Player + O_TILE]
	ld [hli], a
	;Flags
	ld a, [Player + O_FLAGS]
	ld [hli], a	
	ret

SECTION "Attributes", WRAM0
	Player: ds 4
	wVelocity: db
	wJumper: db

	; 0 - rest
	; 1 - fall
	; 2 - jump
	wMoveState: db

SECTION "Counter", WRAM0
	wFrame: db
