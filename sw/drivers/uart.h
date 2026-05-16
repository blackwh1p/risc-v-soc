#ifndef UART_H
#define UART_H

#define UART_BASE      0x40000000
#define UART_TX_DATA   (UART_BASE + 0x00)
#define UART_RX_DATA   (UART_BASE + 0x04)
#define UART_STATUS    (UART_BASE + 0x08)

#define UART_TX_READY   (1 << 0)
#define UART_RX_VALID   (1 << 1)
#define UART_RX_OVERRUN (1 << 2)

void uart_putc(char c);
void uart_puts(const char* str);
char uart_getc(void);
int  uart_overrun(void);

#endif // UART_H