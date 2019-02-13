INCLUDE "gbhw.inc"

SECTION "Vblank", ROM0[$0040]
	reti

SECTION "start", ROM0[$0100]
    nop
    jp main

SECTION "rom header", ROM0[$0104]
    NINTENDO_LOGO	; add nintendo logo. Required to run on real hardware
    ROM_HEADER	"0123456789ABCDE"

main:
    di ; disable interrupts
    ld SP, $FFFF
    ld a, IEF_VBLANK
    ld [rIE], a ; enable just VBlank interrupt
    ei

    halt ; wait a bit
    nop
    halt
    nop

    ld hl, _OAMRAM
    ld [hl], 20 ; y
    ld hl, _OAMRAM + 1
    ld [hl], 130 ; x
    ld hl, _OAMRAM + 2
    ld [hl], $19 ; sprite index
    ld hl, _OAMRAM + 3
    ld [hl], 0 ; set sprite flags to 0

    ld a, [rLCDC]
    or LCDCF_OBJON
    or LCDCF_OBJ8
    ld [rLCDC], a

.loop
    halt ; halt until interrupt
    nop
    ld hl, _OAMRAM ; y
    ld a, [hl]
    inc a
    inc a
    ld [hl], a
    ; ld hl, _OAMRAM + 1 ; x
    ; dec [hl]
    jp .loop




    ; ld a, %00110011 ; set BG palette
    ; ld [rBGP], a

; .loop_until_line_145
;     ld a, [rLY]
;     cp 145
;     jr nz, .loop_until_line_145
;     ld a, [rSCX]
;     inc a
;     ld [rSCX], a
;     ld a, [rSCY]
;     dec a
;     dec a
;     ld [rSCY], a
;     ; ld a, [rBGP] ; get BG palette
;     ; rrc a ; rotate right the bits
;     ; ld [rBGP], a
;     jr .loop_until_line_144