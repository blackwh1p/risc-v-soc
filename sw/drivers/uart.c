#include "uart.h"

void uart_putc(char c) {
    // Wait until the UART is ready to transmit
    while (!(*(volatile unsigned int*)UART_STATUS & UART_TX_READY))
    {
        // Busy wait
    }
    
    // Write the character to the transmit data register
    *(volatile unsigned int*)UART_TX_DATA = (unsigned int)c;
}

void uart_puts(const char* str) {
    while (*str)
    {
        uart_putc(*str++);
    }
}

char uart_getc(void) {
    // Wait until RX byte is available.
    while (!(*(volatile unsigned int*)UART_STATUS & UART_RX_VALID))
    {
        // Busy wait
    }

    return (char)(*(volatile unsigned int*)UART_RX_DATA);
}

int uart_overrun(void) {
    return !!(*(volatile unsigned int*)UART_STATUS & UART_RX_OVERRUN);
}
