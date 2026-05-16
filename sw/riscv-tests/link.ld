OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
    DMEM (rwx) : ORIGIN = 0x20000000, LENGTH = 32K
}

SECTIONS {
    .text.init : { *(.text.init) }  > IMEM
    .text      : { *(.text) *(.text.*) } > IMEM
    .rodata    : { *(.rodata) *(.rodata.*) } > IMEM

    .data : {
        *(.data) *(.data.*)
    } > DMEM

    .bss : {
        *(.bss) *(COMMON)
    } > DMEM
}
