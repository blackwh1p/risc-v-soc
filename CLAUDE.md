# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Simulation Commands

**Run RTL simulations (Icarus Verilog):**
```bash
make sim_alu        # ALU unit test
make sim_regfile    # Register file unit test
make sim_cpu        # Full CPU integration test
make sim_imem       # Instruction memory test
make sim_dmem       # Data memory test
make sim_uart       # UART peripheral test
make sim_timer      # Timer peripheral test
make sim_gpio       # GPIO peripheral test
```

**Build bare-metal firmware:**
```bash
make compile_sw           # Compiles C+ASM → .elf → .bin → .mem (for $readmemh)
make compile_calculator   # Build the calculator demo firmware
make compile_soc_diag     # Build the full-SoC diagnostic firmware
make compile_isa_diag     # Build the ISA regression firmware
```

**Fast bitstream patching (skip full re-synthesis):**
```bash
# Prerequisites: Vivado impl_1/ run must exist; updatemem must be on PATH.
# On Windows: source C:\Xilinx\Vivado\2025.2\settings64.bat first.
# On WSL: source /mnt/c/Xilinx/Vivado/2025.2/settings64.sh first.

make update_bitstream PROG=sw/tests/calculator.elf
# → writes nexys_a7_top_updated.bit (patches IMEM only; takes seconds)
# Then program the board via Vivado Hardware Manager with the updated .bit file.

# Override if your Vivado run directory has a different name:
make update_bitstream PROG=sw/tests/soc_diag.elf VIVADO_IMPL_DIR=my_project.runs/impl_1
```

The `updatemem` tool reads the `.mmi` (memory-map info) file that Vivado generates during `impl_1` to locate the IMEM BRAM in the bitstream. The hierarchical path it targets is `nexys_a7_top/u_soc/u_imem`.

**Clean build artifacts:**
```bash
make clean          # Removes .vvp, .vcd, .elf, .bin, .hex, .map files
```

**View waveforms** (after a sim target generates a `.vcd`):
```bash
gtkwave sim_<module>.vcd
```

## Toolchain Requirements

| Tool | Purpose |
|------|---------|
| `iverilog` + `vvp` | RTL simulation |
| `riscv64-unknown-elf-gcc` | Cross-compiler (`-march=rv32im -mabi=ilp32`) |
| `python3` | `scripts/bin_to_mem.py` — converts `.bin` → `.mem` |
| Xilinx Vivado 2025.2 | FPGA synthesis/implementation (Nexys A7-100T) |

## Architecture Overview

### SoC Structure

`rtl/soc_top.sv` is the top-level integrator. It instantiates CPU, memories, and peripherals, and implements the MMIO address decoder that routes peripheral reads back to the CPU.

```
soc_top
├── cpu (rtl/core/cpu.sv)
│   ├── control_unit  — multi-cycle FSM: FETCH→DECODE→EXECUTE→[MEMORY]→WRITEBACK
│   └── datapath      — PC, register file, ALU, immediate generator, mux network
├── imem (rtl/memory/imem.sv)  — 32 KB instruction ROM at 0x00000000
├── dmem (rtl/memory/dmem.sv)  — 32 KB data RAM at 0x20000000
├── uart (rtl/peripheral/uart.sv)   — MMIO base 0x40000000
├── timer (rtl/peripheral/timer.sv) — MMIO base 0x40001000
└── gpio (rtl/peripheral/gpio.sv)   — MMIO base 0x40002000 (16-bit, LEDs + switches)
```

### CPU Core (Multi-Cycle FSM)

The CPU is **not pipelined** — it uses a multi-cycle FSM. Cycle counts per instruction type:

| Instruction class | Cycles |
|-------------------|--------|
| Branches (taken or not) | 3 (FETCH+DECODE+EXECUTE) |
| Stores | 4 (FETCH+DECODE+EXECUTE+MEMORY) |
| ALU immediate / ALU register / LUI / AUIPC / JAL / JALR | 4 (FETCH+DECODE+EXECUTE+WRITEBACK) |
| Loads | 5 (FETCH+DECODE+EXECUTE+MEMORY+WRITEBACK) |
| RV32M multiply (MUL, MULH, MULHSU, MULHU) | 7 (4 base + 3 MDU cycles) |
| RV32M divide/remainder (DIV, DIVU, REM, REMU) | 38 (4 base + 34 MDU cycles: 32 iterations + finalize) |

`control_unit.sv` drives all datapath control signals; `datapath.sv` contains all state elements and datapaths.

ISA: **RV32IM** — full integer + multiply/divide. ALU supports 16 operations (add, sub, and, or, xor, sll, srl, sra, slt, sltu, mul, mulh, div, divu, rem, remu) encoded in `rtl/core/alu_ops.sv`.

### Memory Map

| Region | Base | Size | Description |
|--------|------|------|-------------|
| IMEM | `0x00000000` | 32 KB | Instruction ROM |
| DMEM | `0x20000000` | 32 KB | Data RAM / stack |
| UART | `0x40000000` | 4 KB | Serial (115200 baud default) |
| Timer | `0x40001000` | 4 KB | Interval timer |
| GPIO | `0x40002000` | 4 KB | 16-bit I/O (LEDs/switches) |
| IMEM write | `0x50000000` | 32 KB | UART bootloader write window |

Full MMIO register-level detail is in `docs/memory_map.md`.

### Software Stack

Bare-metal; no OS. Startup sequence is in `sw/startup/crt0.S`:
1. Set SP to top of DMEM (`0x20007FFC`)
2. Zero `.bss`, copy `.data` from IMEM to DMEM
3. Call `main()`

Linker script: `sw/linker/linker.ld`. Peripheral drivers live in `sw/drivers/` (uart, gpio, timer). Test programs are in `sw/tests/`.

Compiled `.mem` files are loaded into `imem` at simulation time via `$readmemh`.

## Key Conventions

- SystemVerilog (`-g2012`) throughout RTL and testbenches.
- Testbenches use `$display` for pass/fail — no formal assertions framework.
- FPGA target: **Digilent Nexys A7-100T** (Artix-7 XC7A100T), 100 MHz system clock.
- Hardware pins: 16 LEDs, 16 switches, 5 buttons, USB-UART bridge.

---

## Honest Project Assessment

This section is a complete, blunt review of the codebase as of 2026-05-09. It covers real bugs, design weaknesses, documentation errors, and genuine strengths. It is meant to be read before starting any new work so known landmines are not stepped on again.

---

### What genuinely works

- **MDU divide algorithm is correct.** The 32-step restoring division with full RV32M special-case handling (divide-by-zero → all-ones quotient, signed overflow INT_MIN/−1 → INT_MIN quotient with 0 remainder) is correctly implemented in `rtl/core/mdu.sv`.
- **MULHSU sign extension is correct.** `operand_a` is sign-extended to 64 bits; `operand_b` is zero-extended and cast signed (so its top bit is always 0, making it positive) — the signed×unsigned semantics are right.
- **Reset synchronization is real.** `rtl/nexys_a7_top.sv` uses a two-FF synchronizer on `rst_n` deassertion with asynchronous assertion. This is correct metastability practice and better than most student projects.
- **Bare-metal startup is complete and correct.** `sw/startup/crt0.S` correctly zeros BSS word-by-word and copies `.data` from IMEM LMA to DMEM VMA. The linker script `sw/linker/linker.ld` sets the VMA/LMA split properly.
- **ISA diagnostic has real coverage.** `sw/tests/isa_diag.S` covers 53 named test cases: all RV32I arithmetic/logic/shift, branches (taken and not-taken for all 6 conditions), JAL, JALR, LUI, AUIPC, all load/store widths with sign/zero extension, and 6 of the 8 RV32M operations.
- **Package-based encoding is clean.** `riscv_pkg` and `alu_ops` packages centralize all constants. No magic numbers in the RTL.
- **SoC integration structure is coherent.** The peripheral MMIO interface (write_en/read_en/reg_addr/write_data/read_data) is consistent across all three peripherals and correctly wired in `soc_top.sv`.

---

### Real bugs — these cause wrong behavior

**Bug 1 — soc_diag.c fails on real hardware at test #8**
`sw/tests/soc_diag.c:111` calls `gpio_read()` and expects the result to equal `0xA55A`. This test passes in simulation only because `tb/integration/tb_soc_diag.sv:76` hardcodes `switches = 16'hA55A`. On the actual Nexys A7, the switches are almost certainly NOT set to that value, so the SoC diagnostic halts at `fail(8)` and the LEDs display the fail code. The image baked into the FPGA bitstream will visibly fail unless the user manually sets all 16 switches to `0xA55A` before pressing reset. This is the most impactful bug for FPGA use.

**Bug 2 — Double-read of DMEM/MMIO for every load instruction**
`rtl/core/control_unit.sv:252` asserts `mem_read = 1` during STATE_MEMORY (correct — this is the actual read). `control_unit.sv:264` also asserts `mem_read = 1` during STATE_WRITEBACK (wrong — by this state the data is already in the DMEM output register). This causes `dmem_read_en` to go HIGH twice per load: once during MEMORY and again during WRITEBACK. For the current UART peripheral, this accidentally clears `rx_valid` twice, but the second clear is harmless since it's already 0. However, any future peripheral with a read-destructive register (a FIFO pop, an incrementing counter, a hardware-cleared flag that requires exactly one read) will double-pop or double-increment. This is a real latent bug.

**Bug 3 — blink_test.S loads 0xEFFF, not 0xFFFF**
`sw/tests/blink_test.S:14` uses `lui t1, 0x0000F` and comments "t1 = 0x0000FFFF". This is wrong. `lui` loads into the upper 20 bits: `lui t1, 15` sets `t1 = 0x0000_F000`. Then `addi t1, t1, -1` = `0x0000_EFFF`. Bit 12 is 0, so LED[12] is never lit. The comment and the result disagree. The test does not actually turn on all 16 LEDs.

**Bug 4 — MULHSU and MULHU are untested by any diagnostic**
`sw/tests/isa_diag.S` tests MUL, MULH, DIV, DIVU, REM, REMU but never exercises `mulhsu` or `mulhu`. The MDU has special-case paths for both. They pass in `tb/core/tb_mdu.sv` but that bench is not run as part of the `sim_all` integration path, and the compiled ISA diagnostic (which is the most meaningful test) never calls them.

---

### Design weaknesses — won't break the current demo but must be fixed before expanding the design

**Weakness 1 — MMIO address decode is too broad**
`rtl/soc_top.sv:56-58` only checks bits [31:28] and [15:12]. The decode for UART accepts any address whose top nibble is 0x4 and bits[15:12] are 0 — meaning `0x40010000`, `0x4FFF0000`, and `0x41000000` all silently alias to the UART. The correct check also requires bits[27:16] == 12'h000. Similarly, `dmem_sel` accepts the full 256MB 0x2xxxxxxx region, not just 0x20000000–0x20003FFF, so `SW 0x20004000` hits real DMEM at an out-of-bounds index.

**Weakness 2 — `fetch_en` naming is backwards**
`rtl/core/control_unit.sv:137` sets `fetch_en = 0` in STATE_FETCH and `fetch_en = 1` in STATE_DECODE. The name says "fetch enable" but it actually means "the data from the previous fetch cycle is now valid — latch it." The port comment in `control_unit.sv:34` says "HIGH during STATE_FETCH only" which is the opposite of what the code does. Any future developer reading this will be confused and may introduce a real bug.

**Weakness 3 — `alu_zero` and `branch` are dead signals**
`control_unit.sv` takes `alu_zero` as an input (`control_unit.sv:19`) but never references it in any case statement — branch conditions use the separate `branch_eq/branch_lt/branch_ltu` comparators instead. Likewise, `control_unit.sv` outputs `branch` and `datapath.sv` declares it as an input port, but no logic inside the datapath uses the `branch` signal. Both signals are dead weight that obscure the real signal flow.

**Weakness 4 — `alu_result_reg` has no reset**
`rtl/core/datapath.sv:110-115` has no `if (!rst_n)` clause. After hard reset, `alu_result_reg` is X in simulation and undefined on hardware until the first EXECUTE that writes it. The current instruction sequence (FETCH→DECODE→EXECUTE writes it before MEMORY/WRITEBACK reads it) makes this safe in practice, but it is fragile and any change to the initialization sequence could expose it. The aligned-address combinational logic at `datapath.sv:257-263` reads `alu_result_reg` in every state including FETCH and DECODE, which adds unnecessary X-propagation risk in simulation.

**Weakness 5 — GPIO inputs have no synchronizer in RTL**
`rtl/peripheral/gpio.sv:51` reads `gpio_buttons` and `gpio_in` directly with no flip-flop synchronizer. `constraints/nexys_a7.xdc:79-80` declares `set_false_path` on these signals, which silences Vivado's timing report but does not add any metastability protection. Rapid switch changes near a clock edge will cause metastability. For the current demo (user flips switches slowly) this is acceptable, but it should not be treated as correct design.

**Weakness 6 — UART baud counter is hard-wired to 10 bits**
`rtl/peripheral/uart.sv:29` and `:32` declare `tx_baud_counter` and `rx_baud_counter` as `logic [9:0]`. At 50 MHz/115200 baud, `BAUD_DIV = 434` which fits. But at 9600 baud / 100 MHz, `BAUD_DIV = 10416` which needs 14 bits. The counters will silently overflow if the baud rate is ever reduced, producing garbage serial output with no error indication.

**Weakness 7 — GPIO direction register has no effect on outputs**
`rtl/peripheral/gpio.sv:58` does `assign gpio_out = output_reg` regardless of `direction_reg`. A pin configured as input (direction bit = 0) still drives the physical LED if `output_reg` has a 1 in that bit. The direction register is stored but never used. It is dead MMIO state that misleads anyone reading the driver.

**Weakness 8 — `imem` reads on every clock unconditionally**
`rtl/memory/imem.sv:30-33` has no read-enable input. Both the instruction fetch port and the data read port sample the memory array on every clock edge. There is no gating. On FPGA, Vivado infers the BRAM without an enable signal, which slightly increases static power and may complicate BRAM inference with dual-port semantics. Minor, but incorrect relative to what the comment claims ("ROM mode").

**Weakness 9 — Store PC update happens in STATE_MEMORY, not STATE_WRITEBACK**
`rtl/core/control_unit.sv:255` asserts `pc_write_en = 1` during STATE_MEMORY for stores. All other instructions update the PC in STATE_WRITEBACK. This inconsistency is not currently a bug (the FSM correctly skips WRITEBACK for stores), but it means any future refactor of when `pc_write_en` is asserted needs to handle stores as a special case.

**Weakness 10 — CPI documentation is wrong**
`CLAUDE.md` says "Each instruction takes 3–5 clock cycles." Divide takes FETCH(1) + DECODE(1) + EXECUTE(1) + STATE_MDU(34 cycles for 32 iterations plus finalize) + WRITEBACK(1) = **38 cycles**. Multiply takes 6 cycles. The "3-5" claim is only true for RV32I instructions. Any performance analysis based on the documentation will be off by 6–38× for M-extension instructions.

---

### What is missing entirely

- **No interrupt or exception path.** There is no MTVEC, MEPC, MSTATUS, or MCAUSE register. `ECALL` falls through the default case in `control_unit.sv:227` and executes as an I-type arithmetic op (effectively ADDI with x0 as destination). Illegal instructions, misaligned accesses, and system calls are all silently ignored. The CPU is not architecturally RISC-V compliant.
- **No 7-segment display peripheral.** The Nexys A7's 8-digit display has no hardware driver, no XDC entries, and no C driver. It cannot be used without RTL additions.
- **No bootloader or writable instruction memory.** `imem` has no write port. The only way to change the program running on the FPGA is to rebuild the bitstream or patch it with `updatemem`.
- **No timer interrupt connection.** `soc_top.sv:129-130` leaves `timer_interrupt` unconnected (`timer_interrupt()`). Even if the CPU had an interrupt input, the timer could not trigger it.
- **No formal assertions.** All verification is directed test + signature polling. There are no SVA properties, no coverage bins, and no constrained-random stimulus. This means bugs involving unusual instruction sequences or boundary addresses can only be found by accident.
- **MULHSU and MULHU have no end-to-end test.** They are exercised only in `tb/core/tb_mdu.sv` which uses a simple stimulus, not in any compiled software test that runs through the full CPU and MMIO stack.

---

### Summary verdict

**Good for**: An educational RISC-V SoC that demonstrates a working multi-cycle RV32IM CPU, correct bare-metal startup, working MMIO peripherals, a useful ISA regression suite, and a clean simulation-to-FPGA flow. The MDU and startup code are genuinely well done.

**Not good for**: Relying on the current `soc_diag` image as a real FPGA health check (Bug 1 makes it fail by default). Any work that adds new MMIO peripherals with side-effect reads (Bug 2 will double-trigger them). Any assumption that "3-5 cycles per instruction" is accurate (Weakness 10 is off by 10× for divides). Any future expansion that needs interrupts, exceptions, or precise address-space protection.

**Highest-priority fixes before next phase of work:**
1. Fix `soc_diag.c:111` — remove or condition the switch-value check, or add a build-time constant for the expected switch value so simulation and hardware use the same path.
2. Remove the redundant `mem_read = 1` from STATE_WRITEBACK in `control_unit.sv:264`.
3. Tighten MMIO decode in `soc_top.sv:56-58` to match the documented 4 KB peripheral windows.
4. Rename `fetch_en` to `instr_latch_en` or fix its assertion to actually be in STATE_FETCH.
5. Replace the `blink_test.S` LUI+ADDI sequence with `li t1, 0xFFFF` or `addi t1, x0, -1`.
