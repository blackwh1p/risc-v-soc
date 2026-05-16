#ifndef SPI_FLASH_H
#define SPI_FLASH_H

// SPI flash MMIO registers (base 0x40004000)
#define FLASH_BASE      0x40004000U
#define FLASH_DATA      (FLASH_BASE + 0x00U)  // write=TX byte+start, read=RX byte
#define FLASH_STATUS    (FLASH_BASE + 0x04U)  // bit 0 = busy
#define FLASH_CS        (FLASH_BASE + 0x08U)  // bit 0 = CS assert (1 = CS_N low)

// On-flash program storage layout
// Sector 240 of N25Q128A (0xF00000): header + program data
// Offset  0: magic word 0x52564D32 ("RVM2")
// Offset  4: word_count
// Offset  8: word_count * 4 bytes of program (little-endian words)
#define FLASH_PROG_BASE  0x00F00000U
#define FLASH_MAGIC      0x52564D32U

// Returns 1 if a valid program is saved in flash, 0 otherwise.
// Also loads the word count into *out_count.
int   flash_has_program(unsigned int *out_count);

// Load word_count words from flash into the IMEM write window.
void  flash_load_program(unsigned int word_count, unsigned int imem_write_base);

// Save word_count words from IMEM (data port at 0x0) to flash.
// Erases the target sector then writes header + data in 256-byte pages.
void  flash_save_program(unsigned int word_count);

#endif // SPI_FLASH_H
