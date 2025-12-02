SECTION "Pseudo Math", ROM0

PseudoParabola: ;Num Frames: 180
db $01, $02, $01, $01, $02, $01, $01, $01
db $02, $01, $01, $01, $01, $01, $01, $01
db $01, $00, $01, $01, $01, $01, $00, $01
db $01, $00, $01, $00, $01, $00, $01, $00
db $01, $00, $00, $01, $00, $00, $00, $01
db $00, $00, $00, $00, $00
.maximum:
db $00, $00, $00, $00, $00, $FF, $00, $00
db $00, $FF, $00, $00, $FF, $00, $FF, $00
db $FF, $00, $FF, $00, $FF, $FF, $00, $FF
db $FF, $FF, $FF, $00, $FF, $FF, $FF, $FF
db $FF, $FF, $FF, $FF, $FE, $FF, $FF, $FF
db $FE, $FF, $FF, $FE, $FF
.equalibrium:
db $FF, $FE, $FF, $FE, $FE, $FF, $FE, $FF
db $FE, $FE, $FE, $FF, $FE, $FE, $FE, $FE
db $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE
db $FE, $FD, $FE, $FE, $FD, $FE, $FE, $FD
db $FE, $FD, $FE, $FD, $FE, $FD, $FD, $FE
db $FD, $FD, $FE, $FD, $FD, $FD, $FD, $FD
db $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD
db $FD, $FC, $FD, $FD, $FC, $FD, $FD, $FC
db $FD, $FC, $FD, $FC, $FD, $FC, $FC, $FD
db $FC, $FC, $FC, $FD, $FC, $FC, $FC, $FC
db $FC, $FC, $FC, $FC, $FC, $FC, $FC, $FB
db $FC, $FC
EndPseudoParabola:

PseudoSine: ;Num Frames: 140
db $01, $01, $01, $01, $01, $01, $01, $01
db $01, $01, $00, $01, $01, $01, $01, $00
db $01, $01, $01, $00, $01, $00, $01, $00
db $01, $00, $01, $00, $00, $00, $01, $00
db $00, $00, $00, $00, $00, $00, $00, $FF
db $00, $00, $00, $FF, $00, $FF, $00, $FF
db $00, $FF, $00, $FF, $FF, $FF, $00, $FF
db $FF, $FF, $FF, $00, $FF, $FF, $FF, $FF
db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
db $00, $FF, $FF, $FF, $FF, $00, $FF, $FF
db $FF, $00, $FF, $00, $FF, $00, $FF, $00
db $FF, $00, $00, $00, $FF, $00, $00, $00
db $00, $00, $00, $00, $00, $01, $00, $00
db $00, $01, $00, $01, $00, $01, $00, $01
db $00, $01, $01, $01, $00, $01, $01, $01
db $01, $00, $01, $01, $01, $01, $01, $01
db $01, $01, $01, $01
EndPseudoSine:

PseudoCosine: ;Num Frames: 140
db $00, $00, $00, $00, $FF, $00, $00, $00
db $FF, $00, $FF, $00, $FF, $00, $FF, $00
db $FF, $FF, $FF, $00, $FF, $FF, $FF, $FF
db $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF
db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
db $FF, $FF, $FF, $FF, $FF, $00, $FF, $FF
db $FF, $FF, $00, $FF, $FF, $FF, $00, $FF
db $00, $FF, $00, $FF, $00, $FF, $00, $00
db $00, $FF, $00, $00, $00, $00, $00, $00
db $00, $00, $01, $00, $00, $00, $01, $00
db $01, $00, $01, $00, $01, $00, $01, $01
db $01, $00, $01, $01, $01, $01, $00, $01
db $01, $01, $01, $01, $01, $01, $01, $01
db $01, $01, $01, $01, $01, $01, $01, $01
db $01, $01, $01, $00, $01, $01, $01, $01
db $00, $01, $01, $01, $00, $01, $00, $01
db $00, $01, $00, $01, $00, $00, $00, $01
db $00, $00, $00, $00
EndPseudoCosine:

