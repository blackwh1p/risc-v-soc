#include "../drivers/uart.h"
#include "../drivers/spi_flash.h"
#include "../drivers/gpio.h"

/* IMEM write window: SW to this region writes into instruction memory.
   Address 0x50000000 maps to IMEM word 0.
   Bootloader now occupies the top 2 KB (0x7800–0x7FFF = words 7680–8191),
   so the safe user area is words 0–7679 = 30 KB. */
#define IMEM_WRITE_BASE  0x50000000U
#define MAX_WORDS        7680U

static unsigned int recv_u32(void) {
    unsigned int w = (unsigned char)uart_getc();
    w |= (unsigned int)(unsigned char)uart_getc() <<  8;
    w |= (unsigned int)(unsigned char)uart_getc() << 16;
    w |= (unsigned int)(unsigned char)uart_getc() << 24;
    return w;
}

void bootloader_main(void) {
    /* Check BTNC (GPIO_INPUT bit 20): if held at reset → force UART mode,
       skipping the flash-load path. Useful when uploading a new program. */
    unsigned int gpio_val  = *(volatile unsigned int *)GPIO_INPUT;
    int          force_uart = (int)((gpio_val & GPIO_BTNC_MASK) != 0u);

    /* Try to load a saved program from SPI flash. */
    if (!force_uart) {
        unsigned int saved_words = 0u;
        if (flash_has_program(&saved_words) && saved_words <= MAX_WORDS) {
            uart_puts("LOAD\r\n");
            flash_load_program(saved_words, IMEM_WRITE_BASE);
            ((void (*)(void))0x0)();
        }
    }

    /* No valid flash image (or BTNC held): wait for UART upload. */
    uart_puts("BOOT\r\n");

    unsigned int n = recv_u32();
    if (n > MAX_WORDS) n = MAX_WORDS;

    for (unsigned int i = 0u; i < n; i++) {
        unsigned int word = recv_u32();
        *(volatile unsigned int *)(IMEM_WRITE_BASE + i * 4u) = word;
    }

    /* Save the received program to SPI flash so it survives power cycles. */
    uart_puts("SAVE\r\n");
    flash_save_program(n);

    uart_puts("OK\r\n");

    ((void (*)(void))0x0)();
}
