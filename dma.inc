    IF !DEF(DMA_INC)
DMA_INC = 1

; copy x bytes to [de]

COPY_DATA: MACRO
    pop hl ; pop stack address into hl
    push bc
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld c, a
.copy_data_loop\@
    ld a, [hli]
    ld [de], a ; DE should start at $FF80
    inc de ; [de] is the byte dest
    dec bc ; bc is our byte counter
    ld a, b
    or c
    jr nz, .copy_data_loop\@
    pop bc
    jp hl
    reti

DMA_COPY:
  ; load de with the HRAM destination address
  ld  de,$FF80 ; set de to the HRAM address
  rst $28 ; call subroutine at $28
  DB  $00,$0D ; start-end of data
  ; exezin's subroutine data for DMA
  DB  $F5, $3E, $C1, $EA, $46, $FF, $3E, $28, $3D, $20, $FD, $F1, $D9
  ret

    ENDC