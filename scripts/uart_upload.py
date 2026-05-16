#!/usr/bin/env python3
"""
uart_upload.py: Upload a compiled .bin to the RISC-V SoC UART bootloader.

Protocol (board side implemented in sw/tests/bootloader.c):
  1. Board sends "BOOT\\r\\n" on reset.
  2. Host sends 4-byte little-endian word count.
  3. Host sends word_count * 4 bytes of program data (little-endian words).
  4. Board sends "OK\\r\\n" and jumps to 0x0.

Requirements: pip install pyserial

Usage:
  python3 scripts/uart_upload.py <port> <program.bin>

Examples:
  python3 scripts/uart_upload.py /dev/ttyUSB0 sw/tests/calculator.bin
  python3 scripts/uart_upload.py COM3         sw/tests/soc_diag.bin
"""
import sys
import struct

try:
    import serial
except ImportError:
    print("ERROR: pyserial not found — run: pip install pyserial")
    sys.exit(1)

BAUD      = 115_200
MAX_WORDS = 7680   # 30 KB user area (32 KB IMEM minus top 2 KB bootloader)
CHUNK     = 64


def main():
    if len(sys.argv) != 3:
        print("Usage: uart_upload.py <port> <program.bin>")
        sys.exit(1)

    port, bin_path = sys.argv[1], sys.argv[2]

    with open(bin_path, 'rb') as f:
        data = f.read()

    if len(data) % 4:
        data += b'\x00' * (4 - len(data) % 4)

    word_count = len(data) // 4
    if word_count > MAX_WORDS:
        print(f"ERROR: program too large ({word_count} words > {MAX_WORDS} max = 30 KB)")
        sys.exit(1)

    print(f"Uploading {word_count} words ({len(data)} B) via {port} at {BAUD} baud")

    with serial.Serial(port, BAUD, timeout=30) as ser:
        print("Waiting for BOOT banner...", end='', flush=True)
        line = ser.read_until(b'\n')
        if b'BOOT' not in line:
            print(f"\nERROR: unexpected response: {line!r}")
            sys.exit(1)
        print(" received")

        ser.write(struct.pack('<I', word_count))

        for off in range(0, len(data), CHUNK):
            ser.write(data[off:off + CHUNK])
            done = min(off + CHUNK, len(data))
            print(f"\r  {done:5d}/{len(data)} bytes sent", end='', flush=True)
        print()

        while True:
            resp = ser.read_until(b'\n')
            if not resp:
                print("WARNING: timeout waiting for OK")
                break
            if b'SAVE' in resp:
                print("Saving to flash... (may take a few seconds)")
            elif b'OK' in resp:
                print("Done — program saved to flash and running.")
                break
            else:
                print(f"WARNING: unexpected response: {resp!r}")


if __name__ == '__main__':
    main()
