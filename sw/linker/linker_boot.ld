ENTRY(_start)

/* Bootloader occupies the top 2 KB of the 32 KB IMEM (0x7800–0x7FFF).
   User programs are uploaded to 0x0000–0x77FF via the UART bootloader. */
MEMORY
{
    IBOOT (rx)  : ORIGIN = 0x00007800, LENGTH = 2K
    DMEM  (rwx) : ORIGIN = 0x20000000, LENGTH = 32K
}

SECTIONS
{
    .text : {
        *(.text.startup)
        *(.text*)
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(4);
    } > IBOOT

    .bss : {
        _bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > DMEM

    _stack_top = ORIGIN(DMEM) + LENGTH(DMEM) - 4;
}
