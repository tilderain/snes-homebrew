; SNES Custom Startup Code for LLVM-MOS
; Calls the modular crt0 initialization functions before main()

.section .text.startup,"ax",@progbits

; External C function references
.extern main
.extern __do_zero_bss
.extern __do_copy_data
.extern __do_copy_zp_data
.extern __do_init_stack

; Entry point - called by SNES reset vector
.global _startt
_startt:
    ; Call LLVM-MOS crt0 initialization functions

    ;clc
    ;xce         ; Exit Emulation Mode
    ; 1. Initialize the soft stack pointer
    jsl __do_init_stack
    
    ; 2. Copy zero-page data from ROM to RAM (if any)
    jsl __do_copy_zp_data
    
    ; 3. Copy initialized data from ROM to RAM
    jsl __do_copy_data
    
    ; 4. Zero out BSS (uninitialized data)
    jsl __do_zero_bss
    
    ; 5. Call main function
    jsl main
    
    ; If main returns (shouldn't normally), loop forever
 

