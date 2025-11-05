SECTION "Common", ROM0

WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank
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
        ld bc, 160
        call Memset
        ret

; @param hl - obj address
; @param b - x coord
; @param c - y coord
; @param d - tile ID
; @param e - flags
CreateObj:
        ld a, c
        add a, 16
        ld [hli], a
        ld a, b
        add a, 8
        ld [hli], a
        ld a, d
        ld [hli], a
        ld a, e
        ld [hli], a
        ret
        
