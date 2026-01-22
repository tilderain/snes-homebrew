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
    ; 4. Zero out BSS (uninitialized data)
    jsl __do_zero_bss
    

    ; If main returns (shouldn't normally), loop forever
 

