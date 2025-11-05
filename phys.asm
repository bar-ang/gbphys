INCLUDE "hardware.inc"
INCLUDE "common.asm"
INCLUDE "tiles.asm"

SECTION "Header", ROM0[$100]
	jp Main
	ds $150 - @, 0 ; Make room for the header

Main:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

        call WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

        ld de, Tiles
        ld hl, $9000
        ld bc, TilesEnd - Tiles
        call Memcpy

        ld d,  0
        ld hl, $9800
        ld bc, $400
        call Memset

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %00011011
	ld [rBGP], a

