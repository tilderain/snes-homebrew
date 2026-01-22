/* SNES LoROM Linker Script - Fixed Startup & Output Format */

__rc0 = 0x00;
INCLUDE imag-regs.ld
__stack = 0x1FFF;

MEMORY {
    zp (rw)          : ORIGIN = __rc31 + 1, LENGTH = 0x100 - (__rc31 + 1)
    wram (rw)        : ORIGIN = 0x7E2000, LENGTH = 0xE000
    
    /* Bank 0 Split: Code area, Header area, Vector area */
    rom_bank_0 (rx)     : ORIGIN = 0x008000, LENGTH = 0x7FB0
    rom_header (rx)     : ORIGIN = 0x00FFB0, LENGTH = 0x0034
    rom_bank_0_vec (rx) : ORIGIN = 0x00FFE4, LENGTH = 0x001C
    
    /* Remaining Banks */
    rom_bank_1 (rx)  : ORIGIN = 0x018000, LENGTH = 0x8000
    rom_bank_2 (rx)  : ORIGIN = 0x028000, LENGTH = 0x8000
    rom_bank_3 (rx)  : ORIGIN = 0x038000, LENGTH = 0x8000
    rom_bank_4 (rx)  : ORIGIN = 0x048000, LENGTH = 0x8000
    rom_bank_5 (rx)  : ORIGIN = 0x058000, LENGTH = 0x8000
    rom_bank_6 (rx)  : ORIGIN = 0x068000, LENGTH = 0x8000
    rom_bank_7 (rx)  : ORIGIN = 0x078000, LENGTH = 0x8000
    rom_bank_8 (rx)  : ORIGIN = 0x088000, LENGTH = 0x8000
    rom_bank_9 (rx)  : ORIGIN = 0x098000, LENGTH = 0x8000
    rom_bank_10 (rx) : ORIGIN = 0x0A8000, LENGTH = 0x8000
    rom_bank_11 (rx) : ORIGIN = 0x0B8000, LENGTH = 0x8000
    rom_bank_12 (rx) : ORIGIN = 0x0C8000, LENGTH = 0x8000
    rom_bank_13 (rx) : ORIGIN = 0x0D8000, LENGTH = 0x8000
    rom_bank_14 (rx) : ORIGIN = 0x0E8000, LENGTH = 0x8000
    rom_bank_15 (rx) : ORIGIN = 0x0F8000, LENGTH = 0x8000
    rom_bank_16 (rx) : ORIGIN = 0x108000, LENGTH = 0x8000
    rom_bank_17 (rx) : ORIGIN = 0x118000, LENGTH = 0x8000
    rom_bank_18 (rx) : ORIGIN = 0x128000, LENGTH = 0x8000
    rom_bank_19 (rx) : ORIGIN = 0x138000, LENGTH = 0x8000
    rom_bank_20 (rx) : ORIGIN = 0x148000, LENGTH = 0x8000
    rom_bank_21 (rx) : ORIGIN = 0x158000, LENGTH = 0x8000
}

REGION_ALIAS("c_writeable", wram)
REGION_ALIAS("c_readonly", rom_bank_0)

SECTIONS {
    /* --- BANK 0: CRITICAL STARTUP --- */
    /* This MUST catch .text.startup before the regex below does */
    .text.startup : { 
        KEEP(*(._startt)) 
        KEEP(*(.text.startup .text.startup.*))
        *crt0.o(.text .text.*) 
        *(.init .fini)
    } > rom_bank_0

    /* --- BANK 1: LIBRARIES --- */
    .text.libs    : { *libc.a:(.text .text.*) *libgcc.a:(.text .text.*) } > rom_bank_1

    /* --- CODE SPLITTING (WATERFALL) --- */
    .text.u1      : { *(.text.[a-g]* .text.[A-G]*) } > rom_bank_2
    .text.u2      : { *(.text.[h-l]* .text.[H-L]*) } > rom_bank_3
    .text.u3      : { *(.text.[m-p]* .text.[M-P]*) } > rom_bank_4
    
    /* Bank 5 catch: 's' falls here, so we ensured .text.startup was caught above in Bank 0 */
    .text.u4      : { *(.text.[q-z]* .text.[Q-Z]*) } > rom_bank_5
    
    .text.rest    : { *(.text .text.*) } > rom_bank_6

    /* --- ALPHABETICAL DATA (Non-T) --- */
    .rodata.abc : { *(.rodata.[a-f]* .rodata.[A-F]*) } > rom_bank_7
    .rodata.ghi : { *(.rodata.[g-m]* .rodata.[G-M]*) } > rom_bank_8
    .rodata.nqr : { *(.rodata.[n-r]* .rodata.[N-R]*) } > rom_bank_9
    .rodata.s   : { *(.rodata.[s]*   .rodata.[S]*)   } > rom_bank_15
    .rodata.uz  : { *(.rodata.[u-z]* .rodata.[U-Z]*) } > rom_bank_18

    /* --- TILEMAP / SPECIAL DATA --- */
    .rodata.t_lvl0 : { *(.rodata.tilemap_level[0-1]*) } > rom_bank_16
    .rodata.t_lvl2 : { *(.rodata.tilemap_level2[0-9]*) } > rom_bank_17
    .rodata.t_lvl3 : { *(.rodata.tilemap_level[3-4]*) } > rom_bank_19
    .rodata.t_lvl_rest : { *(.rodata.tilemap_level*) } > rom_bank_20
    .rodata.t_general : { *(.rodata.[t]* .rodata.[T]*) } > rom_bank_21

    /* --- LEVEL DATA --- */
    .rodata.levels_low  : { *(.rodata.collision_level[0-9]*) *(.rodata.palette_level[0-9]*) } > rom_bank_11
    .rodata.levels_mid  : { *(.rodata.collision_level1[0-9]*) *(.rodata.palette_level1[0-9]*) } > rom_bank_12
    .rodata.levels_high : { *(.rodata.collision_level2[0-9]*) *(.rodata.palette_level2[0-9]*) } > rom_bank_13
    
    .rodata.rest : { *(.rodata .rodata.*) } > rom_bank_14

    /* RAM values (Initialized data copied from Bank 10) */
    .data : { 
        __data_load_start = LOADADDR(.data);
        __data_start = .;
        *(.data .data.*) 
        __data_end = .;
    } > wram AT> rom_bank_10

    INCLUDE c.ld

    /* --- SNES HEADER & VECTORS (Fixed locations in Bank 0) --- */
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

/* This block is mandatory to stitch the banks into a single binary file */
OUTPUT_FORMAT {
    FULL(rom_bank_0) FULL(rom_header) FULL(rom_bank_0_vec)
    FULL(rom_bank_1) FULL(rom_bank_2) FULL(rom_bank_3) FULL(rom_bank_4)
    FULL(rom_bank_5) FULL(rom_bank_6) FULL(rom_bank_7) FULL(rom_bank_8)
    FULL(rom_bank_9) FULL(rom_bank_10) FULL(rom_bank_11) FULL(rom_bank_12)
    FULL(rom_bank_13) FULL(rom_bank_14) FULL(rom_bank_15) FULL(rom_bank_16)
    FULL(rom_bank_17) FULL(rom_bank_18) FULL(rom_bank_19) FULL(rom_bank_20)
    FULL(rom_bank_21)
}