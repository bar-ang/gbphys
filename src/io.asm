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
        ld a, %00010001
        ld [rNR51], a

        ; --------------------------------------
        ; Configure Channel 1 registers
        ; --------------------------------------

        ; NR10 – Sweep (slow downward sweep)
        ld   a, %01100111      ; period=3, decrease, shift=7
        ld   [rNR10], a

        ; NR11 – Duty + length (high volume, 50% duty)
        ld   a, %01000000      ; duty=01 (50%), length=0
        ld   [rNR11], a

        ; NR12 – Envelope: start loud, fade slowly
        ld   a, %11110111      ; initial=15, decay, sweep=7
        ld   [rNR12], a

        ; Clear music variables
        ld a, 0
        ld [wBGMusicPos], a

        ret

BGMusicStep:
        ; --------------------------------------
        ; Loop frequencies downward
        ; --------------------------------------
        ld hl, BGMusicFreq
        ld a, [wBGMusicPos]
        ld c, a
        ld b, 0
        add hl, bc
        
        ld   a, [hli]           ; low byte
        ld   [rNR13], a
        ld   a, [hli]           ; high byte (trigger bit set later)
        or   a, 0x80         ; set initial trigger bit
        ld   [rNR14], a

        ld a, c
        add a, 2
        cp a, BGMusicFreqEnd - BGMusicFreq
        jp nz, .cont
        ld a, 0
        .cont:
        ld [wBGMusicPos], a
        ret

; --------------------------------------
; Large frequency table (descending)
; Each entry: low_byte, high_byte
; Final marker: FF
; --------------------------------------
BGMusicFreq:
        dw 0x300, 0x355, 0x380, 0x355,   ; C–D–E–D
        dw 0x300, 0x300, 0x200,          ; C–C–G (down)

        dw 0x300, 0x355, 0x380, 0x355,   ; C–D–E–D
        dw 0x300, 0x380, 0x300,          ; C–E–C

        dw 0x380, 0x399, 0x3B0, 0x399,   ; E–F–G–F
        dw 0x380, 0x380, 0x300,          ; E–E–C

        dw 0x355, 0x380, 0x355, 0x300,   ; D–E–D–C
        dw 0x380, 0x300, 0x200           ; E–C–G (ending)

BGMusicFreqEnd:


SECTION "Input Variables", WRAM0
        wCurKeys: db
        wNewKeys: db

SECTION "Audio Variables", WRAM0
        wBGMusicPos: db
