// ============================================================
// File    : calculator.c
// Purpose : Interactive 8-bit calculator demo for RV32IM SoC.
//
// Inputs  : SW[7:0]  → operand A (0–255)
//           SW[15:8] → operand B (0–255)
//           BTNU     → A + B
//           BTNL     → A - B
//           BTNR     → A * B
//           BTND     → A / B  (B=0 yields 0xFFFFFFFF)
//
// Outputs : LEDs[15:0]     = result[15:0]
//           7-seg display  = full 32-bit result in hex
//           UART           = "AA op BB = RRRRRRRR\n"
//
// Design  : Main loop polls buttons and acts only on rising
//           edges (new_press = curr & ~prev), so each button
//           tap fires exactly once with no timer blocking.
// ============================================================

#include "../drivers/uart.h"
#include "../drivers/gpio.h"
#include "../drivers/sevenseg.h"

static void uart_hex8(unsigned int v)
{
    unsigned int n;
    n = (v >> 4) & 0xFu;
    uart_putc((char)(n < 10u ? '0' + n : 'A' + n - 10u));
    n = v & 0xFu;
    uart_putc((char)(n < 10u ? '0' + n : 'A' + n - 10u));
}

static void uart_hex32(unsigned int v)
{
    uart_hex8((v >> 24) & 0xFFu);
    uart_hex8((v >> 16) & 0xFFu);
    uart_hex8((v >>  8) & 0xFFu);
    uart_hex8( v        & 0xFFu);
}

int main(void)
{
    unsigned int prev_buttons = 0u;

    gpio_set_direction(0xFFFFu);
    gpio_write(0x0000u);
    sevenseg_write(0x00000000u);
    sevenseg_enable();

    while (1) {
        unsigned int input     = gpio_read();
        unsigned int sw        = input & 0xFFFFu;
        unsigned int buttons   = (input >> 16) & 0xFu;
        unsigned int new_press = buttons & ~prev_buttons;

        if (new_press) {
            unsigned int a      = sw & 0xFFu;
            unsigned int b      = (sw >> 8) & 0xFFu;
            unsigned int result;
            char         op;

            if      (new_press & 0x1u) { result = a + b;                    op = '+'; }
            else if (new_press & 0x2u) { result = a - b;                    op = '-'; }
            else if (new_press & 0x4u) { result = a * b;                    op = '*'; }
            else                       { result = b ? a / b : 0xFFFFFFFFu;  op = '/'; }

            gpio_write(result & 0xFFFFu);
            sevenseg_write(result);

            uart_hex8(a);
            uart_putc(op);
            uart_hex8(b);
            uart_putc('=');
            uart_hex32(result);
            uart_putc('\n');
        }

        prev_buttons = buttons;
    }

    return 0;
}
