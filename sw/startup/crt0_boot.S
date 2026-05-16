# ============================================================
# File    : crt0_boot.S
# Purpose : Minimal startup for UART bootloader.
#           No .data copy — bootloader has no initialized globals.
# ============================================================

.section .text.startup
.global _start

_start:
    la   sp, _stack_top

    la   t0, _bss_start
    la   t1, _bss_end
    bge  t0, t1, bss_done
bss_loop:
    sw   zero, 0(t0)
    addi t0, t0, 4
    blt  t0, t1, bss_loop
bss_done:

    call bootloader_main

_halt:
    j _halt
