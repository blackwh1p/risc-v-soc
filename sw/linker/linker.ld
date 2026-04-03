ENTRY(_start)

/* Memory regions */
MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    DMEM (rwx) : ORIGIN = 0x20000000, LENGTH = 16K
}

SECTIONS
{
    .text : {
        *(.text.startup)   /* crt0.S goes first */
        *(.text*)          /* all other code */
    } > IMEM

    .data : {
        _data_start = .;   /* start of data in DMEM */
        *(.data*)
        _data_end = .;     /* end of data in DMEM */
    } > DMEM AT > IMEM     /* VMA=DMEM, LMA=IMEM */

    _data_src = LOADADDR(.data);

    .bss : {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > DMEM

    _stack_top = ORIGIN(DMEM) + LENGTH(DMEM) - 4;
}