INCLUDE "gbhw.inc"

SECTION "Vblank", ROM0[$0040]
	reti

SECTION "start", ROM0[$0100]
    nop
    jp main

SECTION "rom header", ROM0[$0104]
    NINTENDO_LOGO	; add nintendo logo. Required to run on real hardware
    ROM_HEADER	"0123456789ABCDE"

SECTION "Main", ROM0[$0150]

dma_copy:
    ld a, $c1
    ld [rDMA], a
    ld a, 40
.loop
    dec a
    jr nz, .loop
    ret
dma_copy_end:
    nop

main:
    di ; disable interrupts
    ld SP, $FFFF
    ld a, IEF_VBLANK
    ld [rIE], a ; enable just VBlank interrupt
    ei

    halt ; wait a bit
    nop

    ld a, [rLCDC] ; set LCD flags
    or LCDCF_OBJON
    or LCDCF_OBJ8
    ld [rLCDC], a
    ; ld a, %11100100 ; set BG palette
    ; ld [rBGP], a

    ld bc, dma_copy
    ld hl, $ff80
    ; DMA routine is 13 bytes long
    REPT dma_copy_end - dma_copy
    ld a, [bc]
    inc bc
    ld [hli], a
    ENDR

clear_oam_buffer:
    ld hl, oam_buffer
    ld a, 0
.clear_oam_buffer_loop
    ld b, 0
    ld [hl], b
    inc hl
    inc a
    cp 160
    jp nz, .clear_oam_buffer_loop

.set_oam_zero ; makes an object using OAM 0
    ld hl, oam_buffer
    ; y-coord
    ld a, 64
    ld [hl+], a
    ; x-coord
    ld [hl+], a
    ; tile index
    ld a, $19
    ld [hl+], a
    ; attributes, including palette, which are all zero
    ld a, %00000000
    ld [hl+], a

.loop
    halt ; halt until interrupt
    nop

    ld hl, oam_buffer
    ld a, [hl]
    inc a
    ld [hl], a

    call $ff80
    jp .loop

SECTION "OAM buffer", WRAM0[$C100]
oam_buffer: ds 4 * 40
