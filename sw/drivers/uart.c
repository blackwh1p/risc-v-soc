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
    // Wait until there is data to read (not implemented in this simple example)
    // In a real implementation, you would check the status register for data availability
    while (!(*(volatile unsigned int*)UART_STATUS & (1 << 1)))
    {
        // Busy wait
    }

    return (char)(*(volatile unsigned int*)UART_RX_DATA);
}