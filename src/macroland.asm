MACRO set_player
	ld [Player.\1], a
	ld e, a
	ld a, [wOAMupdateRequired]
	or a, 1
	ld [wOAMupdateRequired], a
	ld a, e
	
ENDM

MACRO jump_math
	ld a, [wJumpMath]
	inc a
	ld [wJumpMath], a
	ld hl, PseudoParabola
	ld a, [wJumpMath]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld b, a
	ld a, [Player.y]
	sub a, b
	set_player y

	ld a, c; note that c == [wJumpMath]
	cp a, PseudoParabola.maximum - PseudoParabola
	jp c, \1

	; NOTE: map scrolling can only go up
	ld a, 0
	ld [wMapScrollActivated], a

	; switch to REST if hitting the ground
	TestFloorCollision
	jp nz, \1
ENDM

MACRO TestFloorCollision
	ld hl, Player
	ld a, [Player.x]
	add a, 8
	ld b, a
	ld a, [Player.y]
	add a, 8
	ld c, a
	GetTilePos
	GetTile
	cp a, FLOOR_VRAM
ENDM

MACRO TestWallCollisionGoingLeft
	ld hl, Player
	ld a, [Player.x]
	sub a, 1
	ld b, a
	ld a, [Player.y]
	ld c, a
	GetTilePos
	GetTile
	cp a, WALL_VRAM
ENDM


MACRO TestWallCollisionGoingRight
	ld hl, Player
	ld a, [Player.x]
	add a, 16
	ld b, a
	ld a, [Player.y]
	ld c, a
	GetTilePos
	GetTile
	cp a, WALL_VRAM
ENDM

MACRO changeStateREST
	ld a, MOVE_STATE_REST
	ld [wMoveState], a
	ld a, PLAYER_WALK
	ld [Player.tile], a
	ld a, 0
	ld [wMapScrollActivated], a
ENDM

MACRO StartFalling
	ld a, MOVE_STATE_JUMP
	ld [wMoveState], a
	ld a, PLAYER_JUMP
	set_player tile
	ld a, PseudoParabola.maximum - PseudoParabola + 4
	ld [wJumpMath], a
ENDM

MACRO changeStateJUMP
	ld a, MOVE_STATE_JUMP
	ld [wMoveState], a
	ld a, PLAYER_JUMP
	set_player tile
	ld a, 0
	ld [wJumpMath], a
	ld a, 1
	ld [wMapScrollActivated], a
ENDM

MACRO changeStateDYING
	ld a, MOVE_STATE_DYING
	ld [wMoveState], a
	ld a, PLAYER_WALK
	ld [Player.tile], a
	ld a, [Player.flags]
	or a, $40
	set_player flags
	ld a, PseudoParabola.maximum - PseudoParabola + 4
	ld [wJumpMath], a
	ld a, 0
	ld [wMapScrollActivated], a
ENDM

MACRO changeStateDEAD
	ld a, MOVE_STATE_DEAD
	ld [wMoveState], a
ENDM

MACRO PlayerTranslate
	ld a, [Player.x]
	add a, b
	ld [Player.x], a
	ld a, [Player.y]
	add a, c
	ld [Player.y], a
ENDM

