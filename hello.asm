INCLUDE "gbhw.inc"

SECTION "start", ROM0[$0100]
    nop
    jp main

SECTION "rom header", ROM0[$0104]
    NINTENDO_LOGO	; add nintendo logo. Required to run on real hardware
    ROM_HEADER	"0123456789ABCDE"

; $0150: Code!
main:
    di ; disable interrupts
    ld SP, $FFFF
    ld a, %11100100
    ld [rBGP], a
.loop_until_line_144
    ld a, [rLY]
    cp 144
    jr nz, .loop_until_line_144
.loop_until_line_145
    ld a, [rLY]
    cp 145
    jr nz, .loop_until_line_145
    ld a, [rSCX]
    inc a
    ld [rSCX], a
    ld a, [rSCY]
    dec a
    dec a
    ld [rSCY], a
    ld a, [rBGP]
    rrc a
    ld [rBGP], a
    jr .loop_until_line_144