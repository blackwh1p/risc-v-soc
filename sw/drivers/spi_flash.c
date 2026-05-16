#include "spi_flash.h"

// Minimal memset for bare-metal builds (-nostdlib).
// GCC -Os may synthesize a memset call from fill loops even when the
// source has none; providing it here satisfies the linker reference.
void *memset(void *s, int c, unsigned int n) {
    unsigned char *p = (unsigned char *)s;
    while (n--) *p++ = (unsigned char)c;
    return s;
}

// ---- Low-level SPI byte transfer --------------------------------

static unsigned char spi_xfer(unsigned char tx) {
    while (*(volatile unsigned int *)FLASH_STATUS & 1u);
    *(volatile unsigned int *)FLASH_DATA = (unsigned int)tx;
    while (*(volatile unsigned int *)FLASH_STATUS & 1u);
    return (unsigned char)(*(volatile unsigned int *)FLASH_DATA & 0xFFu);
}

static void flash_cs(unsigned int assert) {
    *(volatile unsigned int *)FLASH_CS = assert;
}

// Send 3-byte big-endian address (MSB first)
static void flash_send_addr(unsigned int addr) {
    spi_xfer((unsigned char)((addr >> 16) & 0xFFu));
    spi_xfer((unsigned char)((addr >>  8) & 0xFFu));
    spi_xfer((unsigned char)( addr        & 0xFFu));
}

// ---- N25Q128A command helpers -----------------------------------

static void flash_write_enable(void) {
    flash_cs(1);
    spi_xfer(0x06u);  // WREN
    flash_cs(0);
}

static void flash_wait_ready(void) {
    unsigned char status;
    do {
        flash_cs(1);
        spi_xfer(0x05u);          // RDSR
        status = spi_xfer(0x00u); // dummy to clock out status
        flash_cs(0);
    } while (status & 0x01u);    // WIP bit
}

// Read one 32-bit little-endian word from flash address
static unsigned int flash_read_word_at(unsigned int addr) {
    flash_cs(1);
    spi_xfer(0x03u);  // READ
    flash_send_addr(addr);
    unsigned int w  = (unsigned int)spi_xfer(0x00u);
    w |= (unsigned int)spi_xfer(0x00u) <<  8;
    w |= (unsigned int)spi_xfer(0x00u) << 16;
    w |= (unsigned int)spi_xfer(0x00u) << 24;
    flash_cs(0);
    return w;
}

// ---- Public API -------------------------------------------------

int flash_has_program(unsigned int *out_count) {
    if (flash_read_word_at(FLASH_PROG_BASE) != FLASH_MAGIC)
        return 0;
    *out_count = flash_read_word_at(FLASH_PROG_BASE + 4u);
    return (*out_count > 0u);
}

// Streaming read: keep CS asserted for the whole program block.
void flash_load_program(unsigned int word_count, unsigned int imem_write_base) {
    flash_cs(1);
    spi_xfer(0x03u);                     // READ
    flash_send_addr(FLASH_PROG_BASE + 8u); // skip header
    for (unsigned int i = 0; i < word_count; i++) {
        unsigned int w  = (unsigned int)spi_xfer(0x00u);
        w |= (unsigned int)spi_xfer(0x00u) <<  8;
        w |= (unsigned int)spi_xfer(0x00u) << 16;
        w |= (unsigned int)spi_xfer(0x00u) << 24;
        *(volatile unsigned int *)(imem_write_base + i * 4u) = w;
    }
    flash_cs(0);
}

// Write header + program data (from IMEM data port at 0x0) in 256-byte pages.
// Layout in flash: [magic:4][word_count:4][program:word_count*4]
void flash_save_program(unsigned int word_count) {
    // Erase the 64 KB sector that covers FLASH_PROG_BASE
    flash_write_enable();
    flash_cs(1);
    spi_xfer(0xD8u);               // SECTOR ERASE (64 KB)
    flash_send_addr(FLASH_PROG_BASE);
    flash_cs(0);
    flash_wait_ready();            // ~0.8 s typical

    // Write output stream in 256-byte pages.
    // Stream layout (byte indices):
    //   0-3  : magic
    //   4-7  : word_count
    //   8+   : program words (little-endian) read from IMEM data port
    unsigned int flash_addr  = FLASH_PROG_BASE;
    unsigned int total_bytes = 8u + word_count * 4u;
    unsigned char page[256];
    unsigned int  page_pos = 0u;

    for (unsigned int b = 0u; b < total_bytes; b++) {
        unsigned char byte_val;
        if (b < 4u) {
            byte_val = (unsigned char)((FLASH_MAGIC >> (b * 8u)) & 0xFFu);
        } else if (b < 8u) {
            byte_val = (unsigned char)((word_count >> ((b - 4u) * 8u)) & 0xFFu);
        } else {
            // Read from IMEM via the data port (address 0x0 = IMEM word 0)
            unsigned int imem_off = b - 8u;
            unsigned int word_val = *(volatile unsigned int *)((imem_off >> 2) * 4u);
            byte_val = (unsigned char)((word_val >> ((imem_off & 3u) * 8u)) & 0xFFu);
        }
        page[page_pos++] = byte_val;

        // Flush a full 256-byte page or the last partial page
        if (page_pos == 256u || b == total_bytes - 1u) {
            while (page_pos < 256u)
                page[page_pos++] = 0xFFu;  // pad with erased-flash value
            flash_write_enable();
            flash_cs(1);
            spi_xfer(0x02u);               // PAGE PROGRAM
            flash_send_addr(flash_addr);
            for (unsigned int j = 0u; j < 256u; j++)
                spi_xfer(page[j]);
            flash_cs(0);
            flash_wait_ready();            // ~5 ms typical
            flash_addr += 256u;
            page_pos    = 0u;
        }
    }
}
