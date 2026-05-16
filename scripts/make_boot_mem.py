#!/usr/bin/env python3
"""
make_boot_mem.py: Build the combined bootloader .mem image for $readmemh.

Layout (8192 words = 32 KB IMEM):
  words 0..7679    : zeros  (user program uploaded here at runtime)
  words 7680..8191 : bootloader binary (max 512 words = 2 KB)

Usage: python3 scripts/make_boot_mem.py <bootloader.bin> <output.mem>
"""
import sys
import struct

IMEM_WORDS   = 8192
BOOT_OFFSET  = 7680   # word index where bootloader begins (byte 0x7800)
MAX_BOOT_WDS = IMEM_WORDS - BOOT_OFFSET  # 512

def main():
    if len(sys.argv) != 3:
        print("Usage: make_boot_mem.py <bootloader.bin> <output.mem>")
        sys.exit(1)

    bin_path, mem_path = sys.argv[1], sys.argv[2]

    with open(bin_path, 'rb') as f:
        data = f.read()

    # Pad to 4-byte boundary
    if len(data) % 4:
        data += b'\x00' * (4 - len(data) % 4)

    boot_words = len(data) // 4
    if boot_words > MAX_BOOT_WDS:
        print(f"ERROR: bootloader too large ({boot_words} words > {MAX_BOOT_WDS} max)")
        sys.exit(1)

    with open(mem_path, 'w') as f:
        for _ in range(BOOT_OFFSET):
            f.write("00000000\n")
        for i in range(0, len(data), 4):
            f.write(f"{struct.unpack_from('<I', data, i)[0]:08x}\n")
        for _ in range(MAX_BOOT_WDS - boot_words):
            f.write("00000000\n")

    print(f"Wrote {IMEM_WORDS} words to {mem_path}")
    print(f"  zero pad  : words 0–{BOOT_OFFSET-1} (0x0000–0x{(BOOT_OFFSET*4-1):04X})")
    print(f"  bootloader: {boot_words} words at 0x7800")

if __name__ == '__main__':
    main()
