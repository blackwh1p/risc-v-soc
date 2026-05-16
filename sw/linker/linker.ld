ENTRY(_start)

/* Memory regions */
MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
    DMEM (rwx) : ORIGIN = 0x20000000, LENGTH = 32K
}

SECTIONS
{
    .text : {
        *(.text.startup)   /* crt0.S goes first */
        *(.text*)          /* all other code */
    } > IMEM

    .rodata : {
        *(.rodata*)        /* string literals, const tables */
        *(.srodata*)
        . = ALIGN(4);
    } > IMEM

    .data : {
        _data_start = .;   /* start of initialized data in DMEM */
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
        _data_end = .;     /* end of initialized data in DMEM */
    } > DMEM AT > IMEM     /* VMA=DMEM, LMA=IMEM */

    _data_src = LOADADDR(.data);

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
