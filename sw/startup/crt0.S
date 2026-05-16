# ============================================================
# File    : crt0.S
# Purpose : C runtime startup code for RV32IM bare-metal
#           Runs before main() to initialize the C environment
# ============================================================

.section .text.startup
.global _start

_start:

    # --------------------------------------------------------
    # Step 1 — Set stack pointer
    # Point sp to top of DMEM (0x20003FFC)
    # --------------------------------------------------------
    la sp, _stack_top

    # --------------------------------------------------------
    # Step 2 — Zero the .bss section
    # _bss_start and _bss_end are defined by the linker script
    # --------------------------------------------------------
    la   t0, _bss_start     # load address of bss start into t0
    la   t1, _bss_end       # load address of bss end into t1
    bge  t0, t1, bss_done

    loop_word:
        sw zero, 0(t0)
        addi t0, t0, 4
        blt t0, t1, loop_word

    bss_done:

    # --------------------------------------------------------
    # Step 3 — Copy initialized data (.data/.sdata) from IMEM to DMEM
    # --------------------------------------------------------
    la   t0, _data_src      # source in IMEM
    la   t1, _data_start    # destination in DMEM
    la   t2, _data_end      # end of destination
    bge  t1, t2, data_done

    loop_copy:
        lw t3, 0(t0)
        sw t3, 0(t1)
        addi t0, t0, 4
        addi t1, t1, 4
        blt t1, t2, loop_copy

    data_done:

    # --------------------------------------------------------
    # Step 4 — Call main()
    # --------------------------------------------------------
    call main

    # --------------------------------------------------------
    # Step 5 — Loop forever if main() returns
    # --------------------------------------------------------
    _halt:
        j _halt
