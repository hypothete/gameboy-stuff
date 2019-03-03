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
    ROM_HEADER	"DUNCS CROSSHAIR"

INCLUDE	"ibmpc1.inc"	; used to generate ascii characters in our ROM
INCLUDE "memory.asm"	; used to copy Monochrome ascii characters to VRAM

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

    call lcd_off

load_chars:
    ld de, $8800
    ld hl, IBMCHARS_START
    ld bc, IBMCHARS_END - IBMCHARS_START
    call mem_CopyMono

draw_to_bg:
    ld hl, $9800
    ld d, 0
    ld e, 0
.xloop
    ld [hl], $81
    inc hl
    inc d
    ld a, d
    cp $14
    jp nz, .xloop
.yloop
    inc e
    ld d, 0
    ld bc, $0C
    add hl, bc
    ld a, e
    cp $12
    jp nz, .xloop

    call lcd_on

draw_objects:
    ld a, [rLCDC] ; set LCD flags
    or LCDCF_OBJON
    or LCDCF_OBJ8
    ld [rLCDC], a

    ld bc, dma_copy
    ld hl, $ff80
    ; DMA routine is 13 bytes long
    REPT dma_copy_end - dma_copy
    ld a, [bc]
    inc bc
    ld [hli], a
    ENDR

set_object_palette:
    ld hl, rOBP0
    ld [hl], %11100100

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
    ld a, $82
    ld [hli], a
    ; attributes, including palette, which are all zero
    ld a, %00000000
    ld [hli], a

.loop
    halt ; halt until interrupt
    nop

    call read_buttons
    ld hl, oam_buffer
    ld b, [hl] ; set b to oam 0 y
    inc hl
    ld c, [hl] ; set c to oam 0 x
    ld a, [buttons]
    bit PADB_LEFT, a
    jr z, .skip_left ; if not pressing left jump to .skip_left
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
    ld [hl], c ; set x and y
    dec hl
    ld [hl], b

    ld hl, rBGP ; mess with the bg palette
    ld [hl], %11011000
    ld hl, rOBP0
    ld [hl], %11100100
    bit PADB_A, a
    jr z, .skip_a
    ld hl, rBGP
    ld [hl], %00100111

    ld hl, rOBP0 ; invert objects
    ld [hl], %00011011
.skip_a

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

lcd_off:
    ld a, [rLCDC]
    and LCDCF_ON
    ret z
.wait4vblank
    ldh a, [rLY]
    cp 145
    jr nz, .wait4vblank
.stopLCD
    ld a, [rLCDC]
    xor LCDCF_ON
    ld [rLCDC], a
    ret

lcd_on:
    ld a, [rLCDC]
    or LCDCF_ON
    ld [rLCDC], a
    ret

SECTION "Sprites", ROM0
IBMCHARS_START:
    chr_IBMPC1 1,8
IBMCHARS_END:
SECTION "Buffers", WRAM0[$C100]
oam_buffer: ds 4 * 40
buttons: db