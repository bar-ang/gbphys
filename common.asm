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

ObjGetPosition:
        ld a, [hli]
        sub a, 16
        ld c, a
        ld a, [hli]
        sub a, 8
        ld b, a
        ret
        
ObjTranslate:
        ld a, [hl]
        add a, c
        ld [hli], a
        ld a, [hl]
        add a, b
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
