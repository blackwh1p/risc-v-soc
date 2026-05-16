# FPGA Programming and Display Plan

## Current State

The SoC is currently a simple RV32IM system running at a temporary 50 MHz board bring-up clock.

Current hardware-visible interfaces:

- UART at `0x40000000`
- Timer at `0x40001000`
- GPIO at `0x40002000`
- LEDs connected to GPIO output
- Switches and four non-reset buttons connected to GPIO input

Current instruction storage:

- Firmware is linked to start at `0x00000000`.
- `imem` is initialized with `$readmemh(MEM_FILE, mem)`.
- Vivado bakes that memory image into BRAM initialization values in the bitstream.
- The current board build selects `soc_diag.mem`.

This means the FPGA currently boots one fixed program image from initialized BRAM.

## Testing Normal Programs

The simplest next test is a normal C program that writes calculation results to LEDs and UART.

Example program behavior:

- Read operands from switches.
- Use `a = switches[7:0]`.
- Use `b = switches[15:8]`.
- Compute `a + b`, `a * b`, or another operation.
- Write the result to LEDs with `gpio_write(result)`.
- Optionally print the result over UART.

This tests normal C execution, arithmetic instructions, GPIO, and UART without needing new RTL.

The existing flow already supports this:

- `make compile_sw` compiles `sw/tests/main.c`.
- The output memory image is `sw/tests/program.mem`.
- To boot that image on FPGA, the Vivado memory image must be changed from `soc_diag.mem` to `program.mem`, or the bitstream must be patched with the new memory image.

For quick validation, LEDs are enough. UART is better for debugging because it can print exact values.

## 7-Segment Display Support

The current hardware does not drive the Nexys A7 seven-segment display.

To use it, the design needs new hardware:

- Add top-level ports for segment cathodes/anodes, decimal point, and digit enables.
- Add Nexys A7 pin constraints for those ports.
- Add a new MMIO peripheral, for example at `0x40003000`.
- Add a C driver for that peripheral.

Recommended peripheral interface:

| Address | Register | Purpose |
|---------|----------|---------|
| `0x40003000` | VALUE | 32-bit value to display as 8 hex digits |
| `0x40003004` | CTRL | enable, mode flags, decimal/hex mode |
| `0x40003008` | DOTS | decimal point mask |

Recommended hardware behavior:

- CPU writes one 32-bit value to `VALUE`.
- Seven-segment peripheral continuously multiplexes the 8 digits.
- Display refresh is done in hardware, not in a CPU busy loop.

The Nexys A7 seven-segment display is typically active-low/common-anode style, so the peripheral should drive one digit enable at a time and output active-low segment patterns.

## Calculator Program

A simple FPGA calculator is feasible after adding the seven-segment peripheral.

Possible user interface:

- `SW[7:0]`: operand A
- `SW[15:8]`: operand B
- Buttons select operation:
  - button 0: add
  - button 1: subtract
  - button 2: multiply
  - button 3: divide or clear
- LEDs show flags or low result bits.
- Seven-segment display shows the result.

Firmware structure:

```c
while (1) {
    unsigned int sw = gpio_read();
    unsigned int a = sw & 0xffu;
    unsigned int b = (sw >> 8) & 0xffu;
    unsigned int buttons = (sw >> 16) & 0x0fu;
    unsigned int result;

    if (buttons & 1u)
        result = a + b;
    else if (buttons & 2u)
        result = a - b;
    else if (buttons & 4u)
        result = a * b;
    else
        result = 0;

    sevenseg_write_hex(result);
    gpio_write(result);
}
```

The exact button bit mapping should match the existing GPIO input register layout:

- `gpio_read()` returns `{12'b0, gpio_buttons[3:0], switches[15:0]}`.
- Therefore buttons are bits `[19:16]`.

## Avoiding Full Synthesis/Implementation for C Changes

The current workflow is not ideal for software iteration because changing C changes the BRAM initialization contents.

There are three practical levels of improvement.

### Level 1: Current Simple Flow

Compile C to `.mem`, then rerun Vivado bitstream generation.

This is simple but slow if Vivado decides synthesis/implementation are out of date.

### Level 2: Patch BRAM Contents in an Existing Bitstream

This is the best near-term workflow.

Goal:

- Synthesize and implement the hardware once.
- Generate a routed checkpoint and base bitstream once.
- Compile new C programs to `.mem` or `.elf`.
- Patch the BRAM initialization in the existing bitstream.
- Program the patched bitstream.

This avoids full synthesis and implementation for every C edit.

Xilinx's intended mechanism is generally the `updatemem`/MMI flow, or an equivalent Tcl script that opens the routed checkpoint, updates BRAM `INIT` values, and writes a new bitstream.

Important caveat:

- Because this is a custom CPU, we may need to create or verify the memory map metadata manually.
- The update flow must correctly map 32-bit instruction words into the physical RAMB36 primitives that implement `imem`.
- Once configured, this should become a fast "compile software and patch bitstream" workflow.

### Level 3: Runtime Program Loading

This is the clean long-term architecture if you want to change programs without rebuilding or patching bitstreams.

Options:

- UART bootloader: fixed ROM bootloader receives a program over serial and writes it into instruction RAM.
- SPI flash bootloader: fixed ROM bootloader copies a program image from onboard flash into instruction RAM.
- SD-card bootloader: fixed ROM bootloader loads a program from SD card or raw block storage.
- JTAG/debug loader: host writes instruction RAM directly through a debug interface.

Current blocker:

- `imem` is ROM-like from software's perspective.
- The CPU fetch path only fetches from `imem`.
- There is no instruction-memory write port exposed to software.
- There is no bootloader, SPI flash controller, SD controller, or debug module.

Therefore runtime loading requires hardware changes.

## "Without Running on Computer"

A new C program cannot appear in FPGA memory by itself.

If the program is stored in BRAM initialization, then it is part of the bitstream. A computer or programmer must create/program that bitstream or patched bitstream.

To change programs without a computer after deployment, the board needs a nonvolatile program source and a loader:

- Store FPGA bitstream in QSPI flash.
- Store application image in QSPI flash, SD card, or another external medium.
- Bootloader copies that application into writable instruction memory.
- CPU jumps to the loaded application.

That is a larger architecture step, but it is the right direction for standalone operation.

## Recommended Roadmap

1. Keep the current diagnostic bitstream as the known-good hardware baseline.
2. Add a simple LED/UART calculator C program first, without changing RTL.
3. Set up a fast bitstream patch flow for changing `.mem` or `.elf` without rerunning synthesis/implementation.
4. Add a seven-segment MMIO peripheral and C driver.
5. Build the calculator UI on switches/buttons plus seven-segment output.
6. Later, add a bootloader and writable instruction memory if standalone program loading is required.

---

## Claude Code Assessment

### On Testing With a Normal Program Right Now

You can run an addition or multiplication test on the FPGA today without changing any RTL. The hardware already has everything needed:

- `SW[7:0]` → operand A (8-bit)
- `SW[15:8]` → operand B (8-bit)
- `A + B` or `A * B` result → `gpio_write(result)` → visible on all 16 LEDs
- `uart_puts` can print the exact decimal/hex value to a terminal

A simple `while(1)` loop that reads switches and writes to LEDs compiles with the existing `make compile_sw` flow. The 16 LEDs give you 16 bits of result visibility, which is enough for 8-bit × 8-bit = 16-bit multiplication. This is a useful first test that validates the CPU, GPIO driver, and MMIO path all at once on real hardware, and it requires zero RTL changes.

The only cost is one Vivado bitstream build with the new `.mem` file. After that, the `updatemem` flow described below handles all future C changes.

### On Avoiding Re-Synthesis: `updatemem` Is the Right Answer

Codex described this correctly as "Level 2", but the concrete workflow is worth spelling out because it is simpler than it sounds.

Vivado automatically writes a Memory Map Information (`.mmi`) file during implementation. This file describes exactly how the logical `imem` array maps onto the physical RAMB36 primitives in the bitstream. You do not need to write this file by hand — Vivado generates it for `$readmemh`-initialized BRAMs.

The workflow after the first Vivado run:

1. After `impl_1` completes, find `nexys_a7_top.mmi` in the `impl_1` output directory. Keep this file alongside the base bitstream.
2. Write new C code, run `make compile_sw` (or the appropriate `compile_*` target), which produces a `.elf` file.
3. Run `updatemem` to patch the BRAM init values into the existing bitstream:

```
updatemem \
  -meminfo  nexys_a7_top.mmi \
  -data     sw/tests/program.elf \
  -bit      nexys_a7_top.bit \
  -proc     nexys_a7_top/u_soc/u_imem \
  -out      nexys_a7_top_updated.bit
```

4. Program the patched bitstream to the FPGA with Vivado hardware manager or `openFPGALoader`.

`updatemem` takes roughly 5–10 seconds. Full synthesis+implementation takes 20–40 minutes. This is the difference between a comfortable iteration loop and a workflow that discourages experimentation.

The `updatemem` tool takes the ELF file directly and reads the section layout from it. Our Makefile already produces `.elf` files for all software targets, so no extra step is needed. The ELF sections map to `0x00000000` per the linker script, which matches the imem base address — `updatemem` uses this to place the words into the correct BRAM locations.

A practical addition to the Makefile would be:

```make
update_bitstream: compile_sw
	updatemem \
	  -meminfo impl_1/nexys_a7_top.mmi \
	  -data    sw/tests/program.elf \
	  -bit     impl_1/nexys_a7_top.bit \
	  -proc    nexys_a7_top/u_soc/u_imem \
	  -out     nexys_a7_top_updated.bit
```

### On "Without Running on Computer"

To be precise about what is and is not avoidable:

- Cross-compilation (riscv-gcc, bin_to_mem.py) always requires a computer. This is unavoidable — converting C source to machine code requires the toolchain.
- Full Vivado synthesis and implementation can be avoided after the first run, using `updatemem` as above.
- Programming the FPGA always requires a computer connected to the board via USB-JTAG or a configuration cable.

True standalone operation — where you can load a new program without any computer connection at all — requires a bootloader and a nonvolatile storage device on the board. The Nexys A7 has a QSPI flash chip and an SD card slot. A bootloader stored in a small ROM region could read a program image from the SD card or SPI flash and write it into a writable instruction memory, then jump to it. This is architecturally clean and removes the computer entirely from the loop after initial bitstream deployment, but it requires two hardware changes: making `imem` writable via a load port, and adding an SD or SPI flash controller. That is a meaningful amount of work and not necessary for the current goals.

The practical answer for now: `updatemem` eliminates re-synthesis, and the iteration cost reduces to a ~10-second patch + FPGA programming. That is fast enough for active software development.

### On the 7-Segment Display

Codex's peripheral register model is correct. A few hardware-level details that matter for implementation:

The Nexys A7 seven-segment display is common-anode with active-low control signals. The eight anode enables (`AN[7:0]`) are active-low — pulling an anode low connects that digit's common to VCC, enabling it. The seven cathode segments (`CA`–`CG`) plus decimal point (`DP`) are also active-low — pulling a cathode low illuminates that segment. The XDC already declares these pins.

The scan controller must refresh all 8 digits fast enough to appear steady to the human eye. A digit scan rate between 1 kHz and 5 kHz per digit is standard, meaning the full 8-digit frame cycles at 125 Hz to 625 Hz. At 50 MHz, dividing by 12500 gives a 4 kHz per-digit scan rate, which is a clean power-of-two-ish divisor. The peripheral should contain this counter and drive the anode/segment outputs directly from hardware — the CPU should only write one 32-bit value to the `VALUE` register and never touch the scan loop.

The segment encoding for hexadecimal digits (0–F) can be stored as a 16-entry lookup table inside the peripheral. The peripheral extracts each 4-bit nibble from `VALUE` based on the current digit index and outputs the corresponding 7-segment pattern. This makes the C driver trivially simple: one store instruction.

The 16 new output pins (`AN[7:0]`, `CA`–`CG`, `DP`) need to be added to `nexys_a7_top.sv` as top-level ports and connected through `soc_top.sv` to the peripheral. The XDC constraint block already has the standard Nexys A7 names for these pins; they just need to be uncommented or added to the constraint file.

### Recommended Iteration Order

Given the current state of the project, this is the most efficient path to a working calculator demo:

1. **Immediate (no RTL change)**: Write a `calculator.c` that reads switches, computes A+B and A*B in a loop, and writes results to LEDs and UART. Build with `make compile_sw`. Run one Vivado bitstream build. Save the `.mmi` file from `impl_1`. This validates the hardware and establishes the `updatemem` baseline.

2. **Next (one `updatemem` per C change)**: Iterate freely on the C calculator logic. Each change costs 10 seconds + FPGA programming time, not 40 minutes.

3. **After that (RTL change, one more synthesis)**: Add the 7-segment peripheral. This requires new RTL in `soc_top.sv`, new ports in `nexys_a7_top.sv`, new XDC entries, and a new C driver. After one more synthesis/implementation run, you have a new `.mmi` baseline and go back to the fast `updatemem` loop.

4. **Later (large effort, optional)**: UART bootloader + writable `imem` if you want to eliminate `updatemem` entirely and load programs over serial. This is the cleanest long-term architecture but should wait until the calculator demo is stable.

