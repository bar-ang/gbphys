SECTION "Printer", ROM0

DEF NUMERAL      EQU 0x8800
DEF NUMERAL_SIZE EQU 8

; @param - pointer to the bytes we wish to print in HL
LoadBytesTiles:
        ld a, NUMERAL_SIZE
        ld de, NUMERAL ; the addr to load the tiles
        push af
        .loop:
                ; loop counter (make it loop 4 times)
                pop af
                cp a, 0
                jp z, .done
                dec a
                push af


                ld a, [hli] ; a contains the number to load
                push hl     ; saving hl
                
                ld h, d
                ld l, e     ; hl is now the address where to put the tile
                push hl
                call LoadNumberTile
                pop hl
                ld de, 0x10
                add hl, de
                ld d, h
                ld e, l
                
                pop hl
                jp .loop
        .done:
        ret


; @param - number in a
; @param - address in hl
LoadNumberTile:
        ; saving original value of a for later
        ld b, a
        ; calculating: de = a*16
        and a, 0xf
        swap a
        ld e, a
        ; now the regs satisfy: e == LOW(a) * 16
        ; the rest of a will be set in d
        ld a, b
        and a, 0xf0
        swap a
        ld d, a
        
        ; calculating: de += ASCII
        ld a, e
        add a, LOW(ASCII)
        ; in case 'e + LOW(ASCII)' results in a carry
        ; we'll load d, increment it, and store it again
        ; then proceed with the calculation
        jp nc, .no_carry
        ld b, a
        ld a, d
        inc a
        ld d, a
        ld a, b
        .no_carry:
        ld e, a

        ld a, d
        add a, HIGH(ASCII)
        ld d, a

        ld bc, 16
        call Memcpy
        ret


