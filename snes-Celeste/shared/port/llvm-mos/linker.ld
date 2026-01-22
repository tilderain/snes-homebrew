/* SNES LoROM Linker Script - Final Code Split (Bank 30 Added) */

__rc0 = 0x00;
INCLUDE imag-regs.ld
__stack = 0x1FFF;

MEMORY {
    zp (rw)          : ORIGIN = __rc31 + 1, LENGTH = 0x100 - (__rc31 + 1)
    wram (rw)        : ORIGIN = 0x7E2000, LENGTH = 0xE000
    
    /* Bank 0: Startup */
    rom_bank_0 (rx)     : ORIGIN = 0x008000, LENGTH = 0x7FB0
    rom_header (rx)     : ORIGIN = 0x00FFB0, LENGTH = 0x0034
    rom_bank_0_vec (rx) : ORIGIN = 0x00FFE4, LENGTH = 0x001C
    
    /* Dedicated Code Banks */
    rom_bank_1 (rx)  : ORIGIN = 0x018000, LENGTH = 0x8000
    rom_bank_2 (rx)  : ORIGIN = 0x028000, LENGTH = 0x8000
    rom_bank_3 (rx)  : ORIGIN = 0x038000, LENGTH = 0x8000
    rom_bank_4 (rx)  : ORIGIN = 0x048000, LENGTH = 0x8000
    rom_bank_5 (rx)  : ORIGIN = 0x058000, LENGTH = 0x8000
    rom_bank_6 (rx)  : ORIGIN = 0x068000, LENGTH = 0x8000
    rom_bank_7 (rx)  : ORIGIN = 0x078000, LENGTH = 0x8000
    rom_bank_8 (rx)  : ORIGIN = 0x088000, LENGTH = 0x8000
    rom_bank_9 (rx)  : ORIGIN = 0x098000, LENGTH = 0x8000
    
    /* RAM Init */
    rom_bank_10 (rx) : ORIGIN = 0x0A8000, LENGTH = 0x8000
    
    /* Level Data */
    rom_bank_11 (rx) : ORIGIN = 0x0B8000, LENGTH = 0x8000
    rom_bank_12 (rx) : ORIGIN = 0x0C8000, LENGTH = 0x8000
    rom_bank_13 (rx) : ORIGIN = 0x0D8000, LENGTH = 0x8000
    
    /* RO Data Catch-all */
    rom_bank_14 (rx) : ORIGIN = 0x0E8000, LENGTH = 0x8000
    
    /* Expanded Storage (Data/Graphics) */
    rom_bank_15 (rx) : ORIGIN = 0x0F8000, LENGTH = 0x8000
    rom_bank_16 (rx) : ORIGIN = 0x108000, LENGTH = 0x8000
    rom_bank_17 (rx) : ORIGIN = 0x118000, LENGTH = 0x8000
    rom_bank_18 (rx) : ORIGIN = 0x128000, LENGTH = 0x8000
    rom_bank_19 (rx) : ORIGIN = 0x138000, LENGTH = 0x8000
    rom_bank_20 (rx) : ORIGIN = 0x148000, LENGTH = 0x8000
    rom_bank_21 (rx) : ORIGIN = 0x158000, LENGTH = 0x8000
    rom_bank_22 (rx) : ORIGIN = 0x168000, LENGTH = 0x8000
    rom_bank_23 (rx) : ORIGIN = 0x178000, LENGTH = 0x8000
    rom_bank_24 (rx) : ORIGIN = 0x188000, LENGTH = 0x8000
    rom_bank_25 (rx) : ORIGIN = 0x198000, LENGTH = 0x8000
    rom_bank_26 (rx) : ORIGIN = 0x1A8000, LENGTH = 0x8000
    rom_bank_27 (rx) : ORIGIN = 0x1B8000, LENGTH = 0x8000
    rom_bank_28 (rx) : ORIGIN = 0x1C8000, LENGTH = 0x8000
    rom_bank_29 (rx) : ORIGIN = 0x1D8000, LENGTH = 0x8000
    
    /* NEW BANK 30 */
    rom_bank_30 (rx) : ORIGIN = 0x1E8000, LENGTH = 0x8000
}

REGION_ALIAS("c_writeable", wram)
REGION_ALIAS("c_readonly", rom_bank_0)

SECTIONS {
    /* --- BANK 0: STARTUP --- */
    .text.startup : { 
        KEEP(*(._startt)) 
        KEEP(*(.text.startup .text.startup.*))
        *crt0.o(.text .text.*) 
        *(.init .fini)
    } > rom_bank_0

    /* --- BANK 1: LIBRARIES --- */
    .text.libs    : { *libc.a:(.text .text.*) *libgcc.a:(.text .text.*) } > rom_bank_1

    /* --- BANK 6: PLAYER UPDATE (HEAVY) --- */
    /* Must appear before generic P regex */
    .text.player_heavy : {
        *(.text.playerU* .text.PlayerU*)
    } > rom_bank_6

    /* --- BANK 5: PORT (HEAVY) --- */
    /* Must appear before generic P regex */
    .text.port_logic : {
        *(.text.port* .text.Port*)
    } > rom_bank_5

    /* --- BANK 8: PLAYER REST + PROCESS --- */
    /* Must appear before generic P regex */
    .text.player_rest : {
        *(.text.player* .text.Player*)
        *(.text.process* .text.Process*)
    } > rom_bank_8

    /* --- BANK 2: A - B --- */
    /* Balloon, BigChest, Breakable */
    .text.group_ab : { 
        *(.text.[a-b]* .text.[A-B]*) 
    } > rom_bank_2

    /* --- BANK 3: C - D --- */
    /* Chest, Clouds, Collapse, Collision, Deco, Double, Draw */
    .text.group_cd : { 
        *(.text.[c-d]* .text.[C-D]*) 
    } > rom_bank_3

    /* --- BANK 4: E - K --- */
    /* Flower, Flying, Game, Init, Key */
    .text.group_ek : { 
        *(.text.[e-k]* .text.[E-K]*) 
    } > rom_bank_4

    /* --- BANK 7: L - O --- */
    /* LoadRoom, Main, Monument, OBJ, OnVblank */
    .text.group_lo : { 
        *(.text.[l-o]* .text.[L-O]*) 
    } > rom_bank_7

    /* --- BANK 9: P(Rest) - S --- */
    /* PlatMov, PlaySound, Smoke, Spring, Strawberry */
    .text.group_ps : { 
        *(.text.[p-s]* .text.[P-S]*) 
    } > rom_bank_9

    /* --- BANK 30: T - Z & CATCH-ALL --- */
    /* Update, Vblank, and any leftover library code */
    .text.group_tz_rest : { 
        *(.text.[t-z]* .text.[T-Z]*) 
        *(.text .text.*) 
    } > rom_bank_30


    /* --- LEVEL TILEMAPS --- */
    .level_dat_0 : { *(.CEL_K_00*) *(CEL_K_00*) } > rom_bank_11
    .level_dat_1 : { *(.CEL_K_01*) *(CEL_K_01*) } > rom_bank_12
    .level_dat_2 : { *(.CEL_K_02*) *(CEL_K_02*) } > rom_bank_13

    /* --- GRAPHICS --- */
    .gfx_sprites : {
        *(.rodata.sprite_gfx*)
        *(.rodata.sprite_palettes*)
    } > rom_bank_25

    .gfx_env : {
        *(.rodata.clouds*)
        *(.rodata.SNESFONT*)
    } > rom_bank_26

    /* --- LEVEL PROPERTIES --- */
    .props_mid : { *(.rodata.*level1[0-9]*) } > rom_bank_22
    .props_high : { *(.rodata.*level2[0-9]*) *(.rodata.*level3[0-9]*) } > rom_bank_23
    .props_low : { *(.rodata.*level[0-9]*) } > rom_bank_24

    /* --- RAM INIT --- */
    .data : { 
        __data_load_start = LOADADDR(.data);
        __data_start = .;
        *(.data .data.*) 
        __data_end = .;
    } > wram AT> rom_bank_10

    /* --- RO DATA --- */
    .rodata.abc : { *(.rodata.[a-f]* .rodata.[A-F]*) } > rom_bank_27
    .rodata.ghi : { *(.rodata.[g-m]* .rodata.[G-M]*) } > rom_bank_28
    .rodata.nqr : { *(.rodata.[n-r]* .rodata.[N-R]*) } > rom_bank_29

    /* --- RO DATA REST --- */
    .rodata.rest : { *(.rodata .rodata.*) } > rom_bank_14

    /* --- OTHER SPECIFIC DATA --- */
    .rodata.s   : { *(.rodata.[s]*   .rodata.[S]*)   } > rom_bank_15
    .rodata.t_lvl0 : { *(.rodata.tilemap_level[0-1]*) } > rom_bank_16
    .rodata.t_lvl2 : { *(.rodata.tilemap_level2[0-9]*) } > rom_bank_17
    .rodata.uz  : { *(.rodata.[u-z]* .rodata.[U-Z]*) } > rom_bank_18
    .rodata.t_lvl3 : { *(.rodata.tilemap_level[3-4]*) } > rom_bank_19
    .rodata.t_lvl_rest : { *(.rodata.tilemap_level*) } > rom_bank_20
    .rodata.t_general : { *(.rodata.[t]* .rodata.[T]*) } > rom_bank_21

    INCLUDE c.ld

    /* --- SNES HEADER & VECTORS --- */
    .snes_header : {
        BYTE(0x30); BYTE(0x30); BYTE(0x54); BYTE(0x53); BYTE(0x54); BYTE(0x31);
        BYTE(0x00); BYTE(0x00); BYTE(0x00); BYTE(0x00); BYTE(0x00); BYTE(0x00); BYTE(0x00);
        BYTE(0x53); BYTE(0x4E); BYTE(0x45); BYTE(0x53); BYTE(0x20); BYTE(0x47); BYTE(0x41); 
        BYTE(0x4D); BYTE(0x45); BYTE(0x20); BYTE(0x20); BYTE(0x20); BYTE(0x20); BYTE(0x20); 
        BYTE(0x20); BYTE(0x20); BYTE(0x20); BYTE(0x20); BYTE(0x20); BYTE(0x20); BYTE(0x20);
        BYTE(0x20); BYTE(0x00); BYTE(0x0A);
        BYTE(0x00); BYTE(0x01); BYTE(0x33); BYTE(0x00);
        SHORT(0x0000); SHORT(0xFFFF);
    } > rom_header

    .vectors : {
        SHORT(0); SHORT(0); SHORT(0); SHORT(0); SHORT(0); SHORT(0); SHORT(0); SHORT(0);
        SHORT(0); SHORT(0); SHORT(0); SHORT(0); SHORT(_startt); SHORT(0);
    } > rom_bank_0_vec

    /DISCARD/ : {
        *(.comment) *(.note*) *(.llvm_addrsig)
    }
}

OUTPUT_FORMAT {
    FULL(rom_bank_0) FULL(rom_header) FULL(rom_bank_0_vec)
    FULL(rom_bank_1) FULL(rom_bank_2) FULL(rom_bank_3) FULL(rom_bank_4)
    FULL(rom_bank_5) FULL(rom_bank_6) FULL(rom_bank_7) FULL(rom_bank_8)
    FULL(rom_bank_9) FULL(rom_bank_10) FULL(rom_bank_11) FULL(rom_bank_12)
    FULL(rom_bank_13) FULL(rom_bank_14) FULL(rom_bank_15) FULL(rom_bank_16)
    FULL(rom_bank_17) FULL(rom_bank_18) FULL(rom_bank_19) FULL(rom_bank_20)
    FULL(rom_bank_21) FULL(rom_bank_22) FULL(rom_bank_23) FULL(rom_bank_24)
    FULL(rom_bank_25) FULL(rom_bank_26) FULL(rom_bank_27) FULL(rom_bank_28)
    FULL(rom_bank_29) FULL(rom_bank_30)
}