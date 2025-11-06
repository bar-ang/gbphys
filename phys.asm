INCLUDE "hardware.inc"
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
	ld b, $10
	ld c, $16
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

Process:
	ld a, [wFrame]
	inc a
	ld [wFrame], a
	call WaitVBlank

	ld a, [wFrame]
	and a, 0x1F
	jp nz, Process

	ld hl, _OAMRAM
	ld b, 0
	ld c, 1
	call ObjTranslate

	jp Process

SECTION "Counter", WRAM0
	wFrame: db
