# Minimal LED test — no C runtime, no UART
# Just turn on all LEDs and halt

.section .text.startup
.global _start

_start:
    # Set stack pointer
    lui  sp, 0x20004
    addi sp, sp, -4

    # Set GPIO direction = all outputs (addr 0x40002000)
    lui  t0, 0x40002          # t0 = 0x40002000
    addi t1, x0, -1           # t1 = 0xFFFFFFFF (GPIO uses [15:0] = 0xFFFF)
    sw   t1, 0(t0)            # DIRECTION = 0xFFFF

    # Write 0xFFFF to GPIO output (addr 0x40002004)
    sw   t1, 4(t0)            # OUTPUT = 0xFFFF

    # Halt forever
halt:
    j halt