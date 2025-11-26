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

        ; --------------------------------------
        ; Loop frequencies downward
        ; --------------------------------------
        ld   hl, StartFreq

FreqLoop:
        ld   a, [hl]           ; low byte
        ld   [rNR13], a
        inc  hl
        ld   a, [hl]           ; high byte (trigger bit set later)
        or   %10000000         ; set initial trigger bit
        ld   [rNR14], a
        inc  hl

        call DelayLong         ; wait for audible duration

        ; Check end of table
        ld   a, [hl]
        cp   $FF
        jr   nz, FreqLoop

        ret

; --------------------------------------
; A long delay (software loop)
; --------------------------------------
DelayLong:
        ld   bc, $5000        ; adjust for longer/shorter effect
DelayLoop:
        dec  bc
        ld   a, b
        or   c
        jr   nz, DelayLoop
        ret


; --------------------------------------
; Large frequency table (descending)
; Each entry: low_byte, high_byte
; Final marker: FF
; --------------------------------------
StartFreq:
        db  $00, $07
        db  $40, $06
        db  $80, $05
        db  $C0, $04
        db  $00, $04
        db  $40, $03
        db  $80, $02
        db  $C0, $01
        db  $00, $01
        db  $40, $00
        db  $FF


SECTION "Input Variables", WRAM0
        wCurKeys: db
        wNewKeys: db
