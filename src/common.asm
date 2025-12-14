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
        
ClearOAM:
        ld de, 0
        ld hl, _OAMRAM
        ld bc, OAMSIZE
        call Memset
        ret

ClearWorkDMA:
        ld de, 0
        ld hl, wDMA
        ld bc, OAMSIZE
        call Memset
        ret

; @param hl - obj address
; @param b - x coord
; @param c - y coord
; @param d - tile ID
; @param e - flags
CreateObj:
        ld a, c
        add a, Y_OFFSET
        ld [hli], a
        ld a, b
        add a, X_OFFSET
        ld [hli], a
        ld a, d
        ld [hli], a
        ld a, e
        ld [hli], a
        ret

; @param bc: x,y coord
; @return block position in bc reg
GetTilePos:
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
        
        ret

; @param bc - position
; @return tile in a reg
; @note Guarantee not to violate the value in BC!
GetTile:
        ld hl, $9800
        add hl, bc
        ld a, [hl]
        ret


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

; @param:
;    (1) address to 16-bit number
;    (2) 8-bit number to add in reg b
; @return: in-place
MACRO add16
	ld a, [\1]
	add a, b
	ld e, f
	ld [\1], a
	ld a, e
	and a, 0x10
	swap a
	ld b, a
	ld a, [\1 + 1]
	add a, b
	ld [\1 + 1], a
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