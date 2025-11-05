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
        
