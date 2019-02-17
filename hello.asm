INCLUDE "gbhw.inc"

SECTION "Vblank", ROM0[$0040]
	reti

SECTION "Joypad", ROM0[$0060]
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

load_sprite:
    ld hl, $8800
    ld bc, SPRITE0
    ld d, 16
.lspr_loop
    ld a, [bc]
    ld [hli], a
    inc bc
    dec d
    jr nz, .lspr_loop


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
    ld [hli], a
    ; x-coord
    ld a, 64
    ld [hli], a
    ; tile index
    ld a, $80
    ld [hli], a
    ; attributes, including palette, which are all zero
    ld a, %00000000
    ld [hli], a

.loop
    halt ; halt until interrupt
    nop

    ; move oam 0 down 1
    call read_buttons
    ld hl, oam_buffer
    ld b, [hl] ; y
    inc hl
    ld c, [hl] ; x
    ld a, [buttons]
    bit PADB_LEFT, a
    jr z, .skip_left
    dec c
.skip_left
    bit PADB_RIGHT, a
    jr z, .skip_right
    inc c
.skip_right
    bit PADB_UP, a
    jr z, .skip_up
    dec b
.skip_up
    bit PADB_DOWN, a
    jr z, .skip_down
    inc b
.skip_down
    ld [hl], c
    dec hl
    ld [hl], b

    call $ff80 ; DMA transfer
    jp .loop

read_buttons:
    ld a, JOYPAD_BUTTONS
    ld [rJOYPAD], a ; tell it we want to read
    ld a, [rJOYPAD] ; stall
    ld a, [rJOYPAD]
    cpl
    and $0F
    swap a
    ld b, a ; b = start.select.b.a.x.x.x.x
    ld a, JOYPAD_ARROWS
    ld [rJOYPAD], a
    ld a, [rJOYPAD] ; stall
    ld a, [rJOYPAD]
    ld a, [rJOYPAD]
    ld a, [rJOYPAD]
    ld a, [rJOYPAD]
    ld a, [rJOYPAD]
    cpl
    and $0F
    or b
    ld [buttons], a
    ld a, $30
    ld [rJOYPAD], a
    ret

SECTION "Sprites", ROM0
SPRITE0:
    dw `00000000
    dw `03022030
    dw `00300300
    dw `02033020
    dw `02033020
    dw `00300300
    dw `03022030
    dw `00000000

SECTION "Buffers", WRAM0[$C100]
oam_buffer: ds 4 * 40
buttons: db