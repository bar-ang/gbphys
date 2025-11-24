SECTION "IO", ROM0

InitKeys:
        ; Initialize global variables
        ld a, 0
        ld [wCurKeys], a
        ld [wNewKeys], a
        ret


UpdateKeys:
        ; Poll half the controller
        ld a, P1F_GET_BTN
        call .onenibble
        ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

        ; Poll the other half
        ld a, P1F_GET_DPAD
        call .onenibble
        swap a ; A7-4 = unpressed directions; A3-0 = 1
        xor a, b ; A = pressed buttons + directions
        ld b, a ; B = pressed buttons + directions

        ; And release the controller
        ld a, P1F_GET_NONE
        ldh [rP1], a

        ; Combine with previous wCurKeys to make wNewKeys
        ld a, [wCurKeys]
        xor a, b ; A = keys that changed state
        and a, b ; A = keys that changed to pressed
        ld [wNewKeys], a
        ld a, b
        ld [wCurKeys], a
        ret

        .onenibble
        ldh [rP1], a ; switch the key matrix
        call .knownret ; burn 10 cycles calling a known ret
        ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
        ldh a, [rP1]
        ldh a, [rP1] ; this read counts
        or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
        .knownret
        ret

InitSound:
    ; Enable master sound
    ld a, %10000000
    ld [rNR52], a

    ; Set output levels (100% to both L and R)
    ld a, %01110111
    ld [rNR50], a

    ; Enable Channel 1 to both outputs
    ld a, %00000001
    ld [rNR51], a

    ret

PlayBeep:
    ld a, %11000000      ; no sweep, but sweep register must NOT be 0x00
    ld [rNR10], a

    ; Duty cycle + length
    ; 01xxxxxx = 12.5% duty
    ld a, %01000000
    ld [rNR11], a

    ; Volume envelope:
    ; 11110000 = start volume 15, no envelope
    ld a, %11110000
    ld [rNR12], a

    ; Frequency low byte
    ld a, $0E
    ld [rNR13], a

    ; Frequency high + trigger
    ; 11000000: restart sound, no sweep
    ld a, %11000110
    ld [rNR14], a

    ret

SECTION "Input Variables", WRAM0
        wCurKeys: db
        wNewKeys: db
