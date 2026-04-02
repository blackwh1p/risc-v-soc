#!/usr/bin/env python3
# ============================================================
# Script  : bin_to_mem.py
# Purpose : Convert a raw binary file to a .mem file
#           suitable for $readmemh in SystemVerilog
# Usage   : python3 scripts/bin_to_mem.py input.bin output.mem
# ============================================================

import sys
import struct

def bin_to_mem(input_file, output_file, mem_depth=4096):
    with open(input_file, 'rb') as f:
        data = f.read()

    with open(output_file, 'w') as f
        for i in range(0, len(data), 4):
            word_bytes = data[i:i+4]
            if len(word_bytes) < 4:
                word_bytes = word_bytes.ljust(4, b'\x00')
            word = struct.unpack('<I', word_bytes)[0]
            f.write(f'{word:08x}\n')

        words_written = (len(data) + 3) // 4
        for _ in range(mem_depth - words_written):
            f.write('00000000\n')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 scripts/bin_to_mem.py input.bin output.mem")
        sys.exit(1)
    bin_to_mem(sys.argv[1], sys.argv[2])
