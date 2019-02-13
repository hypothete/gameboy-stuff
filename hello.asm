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
.loop_until_line_144
    ld a, [rLY]
    ld [rSCX], a
    cp 144
    jp nz, .loop_until_line_144
.loop_until_line_145
    ld a, [rLY]
    cp 145
    jp nz, .loop_until_line_145
    ld a, [rSCY]
    dec a
    ld [rSCY], a
    jp .loop_until_line_144