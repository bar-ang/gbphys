INCLUDE "hardware.inc"
INCLUDE "io.asm"
INCLUDE "common.asm"
INCLUDE "tiles.asm"

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

        ld d,  0
        ld hl, $9800
        ld bc, $400
        call Memset

	ld d, 1
	ld hl, $9A20
	ld bc, $20
	call Memset

	call ClearOAM

	ld hl, _OAMRAM
	ld b, $40
	ld c, $66
	ld d, 0
	ld e, 0
	call CreateObj

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %00011011
	ld [rBGP], a
	ld a, %11100100
	ld [rOBP0], a

	call InitKeys

	; init attributes
	ld a, 1
	ld [wVelocity], a
	ld a, 0
	ld [wJumper], a
	ld a, 1 ; start FALLING
	ld [wMoveState], a
	
Process:
	call WaitVBlank
	ld a, [wFrame]
	inc a
	ld [wFrame], a

	ld a, [wMoveState]
	cp 0
	jp z, .post_switch
	cp 1
	jp z, .fall
	cp 2
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
		ld [wMoveState], a
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
		cp a, 1
		jp nz, .post_switch

		; switch to REST if hitting the ground
		ld a, 0
		ld [wMoveState], a
		
		jp .post_switch
	.post_switch:
	; handle keyboard input
	call UpdateKeys

	; Left
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, .post_left
	
	ld a, [_OAMRAM + 1]
	dec a
	ld [_OAMRAM + 1], a
	.post_left:

	; Right
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, .post_right
	
	ld a, [_OAMRAM + 1]
	inc a
	ld [_OAMRAM + 1], a
	.post_right:


	; Up
	ld a, [wMoveState]
	cp 0
	jp nz, .post_up

	ld a, [wNewKeys]
	and a, PADF_UP
	jp z, .post_up
	
	ld a, 2
	ld [wMoveState], a
	ld a, 100
	ld [wJumper], a
	ld a, -1
	ld [wVelocity],a
	.post_up:

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

SECTION "Attributes", WRAM0
	wVelocity: db
	wJumper: db

	; 0 - rest
	; 1 - fall
	; 2 - jump
	wMoveState: db

SECTION "Counter", WRAM0
	wFrame: db
