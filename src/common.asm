SECTION "Common", ROM0

DEF VISIBLE_RLY EQU 144
DEF X_OFFSET    EQU 8
DEF Y_OFFSET    EQU 16
DEF OAMSIZE     EQU 160

WaitVBlank:
        ld a, [rLY]
        cp VISIBLE_RLY
        jp nc, WaitVBlank
        .wait2:
        ld a, [rLY]
        cp VISIBLE_RLY
        jp c, .wait2
        ret

Memcpy:
        ld a, [de]
        ld [hli], a
        inc de
        dec bc
        ld a, b
        or c
        jp nz, Memcpy
        ret
        

Memset:
        ld a, d
        ld [hli], a
        dec bc
        ld a, b
        or c
        jp nz, Memset
        ret

MACRO RGB_Set
	ld a, ((\2) & $7)
	swap a
	sla a
	or \1
	ld [rBCPD], a

	ld a, \3
	sla a
	sla a
	or a, ((\2) >> 3)
	ld [rBCPD], a
ENDM

MACRO INIT_GBC_PALETTE
  ;NOTE Screen Must be off!
	ld a, $80
	ld [rBCPS], a

  RGB_Set 0, 0, 31
  RGB_Set 31, 0, 0
  RGB_Set 31, 31, 0
  RGB_Set 0, 0, 0

ENDM

MACRO ClearOAM
        ld de, 0
        ld hl, _OAMRAM
        ld bc, OAMSIZE
        call Memset
ENDM

MACRO ClearWorkDMA
        ld de, 0
        ld hl, wDMA
        ld bc, OAMSIZE
        call Memset
ENDM

; @param bc: x,y coord
; @return block position in bc reg
MACRO GetTilePos
        ld d, b
        ld e, c

        ; replacing pixel coords with block pos
        ; this is done by simple division in 8
        srl d
        srl d
        srl d

        srl e
        srl e
        srl e

        ; in 'b' we put the two upper bit of y
        ; note that x, y are both 5 bits
        ld b, e
        srl b
        srl b
        srl b

        ; in c we put the three lower bits of y
        ; and concat to them the value of x
        ld a, e
        sla a
        sla a
        sla a
        sla a
        sla a
        or a, d
        ld c, a
ENDM

; @param bc - position
; @return tile in a reg
; @note Guarantee not to violate the value in BC!
MACRO GetTile
        ld hl, $9800
        add hl, bc
        ld a, [hl]
ENDM


MACRO dma_to_hram
	ld hl, RunHDMA
	ld de, RunDMA
	ld bc, RunDMA.endf - RunDMA
	call Memcpy
ENDM

; @param  number in c
; @return  bc := (c << 5)
MACRO mul32
	ld a, c
	srl a
	srl a
	srl a
	ld b, a
	ld a, c
	and a, $7
	swap a
	sla a
	ld c, a
ENDM

; @param the number to devide
; @return result in reg a
MACRO div8
	ld a, \1
	srl a
	srl a
	srl a
ENDM

; @param: if bc is a sign number, calculate its negative
; @return: in-place
MACRO neg
	ld a, b
	cpl
	ld b, a
	ld a, c
	cpl
	ld c, a
	inc bc
ENDM


SECTION "OAM Transfer", WRAM0, ALIGN[8]
	wDMA: ds $100

SECTION "DMA Transfer Code", ROM0
	RunDMA:
		ld a, HIGH(wDMA)
		ldh [rDMA], a  ; start DMA transfer (starts right after instruction)
		ld a, 40        ; delay for a total of 4×40 = 160 M-cycles
		.wait
			dec a           ; 1 M-cycle
			jr nz, .wait    ; 3 M-cycles
		ret
	.endf
	
SECTION "HDMA Transfer Code", HRAM
	RunHDMA: ds RunDMA.endf - RunDMA