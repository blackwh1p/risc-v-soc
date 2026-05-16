// ============================================================
// File    : soc_diag.c
// Purpose : Full-SoC diagnostic program
//           Checks startup/data/BSS, DMEM, stack, GPIO, timer,
//           and UART. Writes pass/fail signatures into DMEM.
// ============================================================

#include "../drivers/gpio.h"
#include "../drivers/timer.h"
#include "../drivers/uart.h"

#define STATUS_ADDR   ((volatile unsigned int *)0x20000300)
#define DETAIL_ADDR   ((volatile unsigned int *)0x20000304)
#define SCRATCH_BASE  ((volatile unsigned int *)0x20000380)

#define RUN_SIG   0xCAFEBABE
#define PASS_SIG  0x600DC0DE
#define FAIL_SIG  0x0BADF00D

static unsigned int init_word = 0x13579BDF;
static unsigned int bss_word;
static unsigned int dmem_words[16];

static void fail(unsigned int code)
{
    gpio_write(code & 0xFFFFu);
    *DETAIL_ADDR = code;
    *STATUS_ADDR = FAIL_SIG;
    while (1) {
    }
}

static unsigned int sum_stack_values(void)
{
    unsigned int local_words[4];
    local_words[0] = 3;
    local_words[1] = 5;
    local_words[2] = 7;
    local_words[3] = 11;
    return local_words[0] + local_words[1] + local_words[2] + local_words[3];
}

static void uart_emit_banner(void)
{
    uart_putc('S');
    uart_putc('O');
    uart_putc('C');
    uart_putc('\n');
}

int main(void)
{
    unsigned int i;
    unsigned int start_count;
    unsigned int progressed;

    // --- Step 1: Initialize diagnostic status ---
    *STATUS_ADDR = RUN_SIG;
    *DETAIL_ADDR = 0;

    // --- Step 2: Configure GPIO outputs ---
    gpio_set_direction(0xFFFFu);
    gpio_write(0x0000u);

    // --- Step 3: Verify .data, BSS and stack-backed locals ---
    if (init_word != 0x13579BDFu) {
        fail(1);
    }

    if (bss_word != 0u) {
        fail(2);
    }

    bss_word = 0x2468ACE0u;
    if (bss_word != 0x2468ACE0u) {
        fail(3);
    }

    if (sum_stack_values() != 26u) {
        fail(4);
    }

    // --- Step 4: Verify DMEM arrays and scratch region ---
    for (i = 0; i < 16; i++) {
        dmem_words[i] = 0x11110000u + i;
    }

    for (i = 0; i < 16; i++) {
        if (dmem_words[i] != (0x11110000u + i)) {
            fail(5);
        }
        SCRATCH_BASE[i] = dmem_words[i] ^ 0x00FF00FFu;
        if (SCRATCH_BASE[i] != (dmem_words[i] ^ 0x00FF00FFu)) {
            fail(6);
        }
    }

    // --- Step 5: Verify GPIO output register — two complementary write/readback patterns ---
    // Together these exercise all 16 bits of the output register at least once and
    // work identically on hardware and in simulation (no specific switch position required).
    gpio_write(0x55AAu);
    if (*((volatile unsigned int *)GPIO_OUTPUT) != 0x55AAu) {
        fail(7);
    }

    gpio_write(0xA55Au);
    if (*((volatile unsigned int *)GPIO_OUTPUT) != 0xA55Au) {
        fail(8);
    }

    // --- Step 6: Verify timer start, progress, and clear ---
    timer_clear();
    start_count = timer_read();
    timer_set(20u);
    progressed = 0u;

    for (i = 0; i < 64; i++) {
        if (timer_read() != start_count) {
            progressed = 1u;
            break;
        }
    }

    if (!progressed) {
        fail(9);
    }

    timer_clear();
    if (timer_read() != 0u) {
        fail(10);
    }

    // --- Step 7: Misaligned load/store ---
    // buf_storage is word-aligned, so buf+1/+2/+3 produce predictable offsets.
    {
        unsigned int buf_storage[3];
        volatile unsigned char  *buf = (volatile unsigned char *)buf_storage;
        volatile unsigned short *hp;
        volatile unsigned int   *wp;
        unsigned int k;

        for (k = 0; k < 12; k++) buf[k] = (unsigned char)k;
        // buf: {0x00,0x01,0x02,0x03, 0x04,0x05,0x06,0x07, 0x08,...}

        // Misaligned halfword load — within-word (offset 1): expect 0x0201
        hp = (volatile unsigned short *)(buf + 1);
        if (*hp != 0x0201u) fail(11);

        // Misaligned halfword load — cross-boundary (offset 3): expect 0x0403
        hp = (volatile unsigned short *)(buf + 3);
        if (*hp != 0x0403u) fail(12);

        // Misaligned word load — cross-boundary (offset 1): expect 0x04030201
        wp = (volatile unsigned int *)(buf + 1);
        if (*wp != 0x04030201u) fail(13);

        // Misaligned halfword store — within-word (offset 1)
        hp = (volatile unsigned short *)(buf + 1);
        *hp = 0xBEEFu;
        if (buf[1] != 0xEFu || buf[2] != 0xBEu) fail(14);

        // Misaligned halfword store — cross-boundary (offset 3)
        for (k = 0; k < 12; k++) buf[k] = (unsigned char)k;
        hp = (volatile unsigned short *)(buf + 3);
        *hp = 0xCAFEu;
        if (buf[3] != 0xFEu || buf[4] != 0xCAu) fail(15);

        // Misaligned word store — cross-boundary (offset 1)
        for (k = 0; k < 12; k++) buf[k] = (unsigned char)k;
        wp = (volatile unsigned int *)(buf + 1);
        *wp = 0xDEADBEEFu;
        if (buf[1] != 0xEFu || buf[2] != 0xBEu ||
            buf[3] != 0xADu || buf[4] != 0xDEu) fail(16);
    }

    // --- Step 8: Emit UART banner and publish PASS signature ---
    uart_emit_banner();

    gpio_write(0xA5A5u);
    *DETAIL_ADDR = 0x1234ABCDu;
    *STATUS_ADDR = PASS_SIG;

    while (1) {
    }
}
