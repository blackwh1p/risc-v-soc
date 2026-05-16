# Project TODO

Priority scale:
- **P0** — Critical: wrong behavior on real hardware right now
- **P1** — High: must fix before adding any new feature
- **P2** — Medium: required for a complete, reliable SoC demo
- **P3** — Low: future enhancements

Progress markers: `[ ]` open · `[x]` done · `[-]` skipped/won't fix

---

## P0 — Critical Fixes

- [x] **soc_diag.c GPIO input check fails on FPGA**
  Replaced `gpio_read() != 0xA55A` (physical switch check) with a second OUTPUT register
  write/readback using the complementary pattern `0xA55A`. Together with test #7 (`0x55AA`),
  all 16 output-register bits are exercised. Works identically on hardware and simulation.
  Testbench `switches` init changed from `16'hA55A` to `16'h0000`. `soc_diag.mem` recompiled.
  Verified: `sim_soc_diag` passes in 6353 cycles.

- [x] **Double-read of DMEM/MMIO on every load instruction**
  Added `mmio_read_data_reg` flip-flop in `rtl/soc_top.sv` that captures the combinational
  peripheral output at the end of STATE_MEMORY (when `dmem_read_en=1` and `addr[31:28]=4'h4`).
  Updated `dmem_read_data` mux to use `mmio_read_data_reg` instead of live `mmio_read_data`.
  Removed `mem_read = 1` from `OP_I_LOAD` case in STATE_WRITEBACK (`control_unit.sv`).
  Updated `tb_soc_top_decode.sv` MMIO mux checks to clock through the register.
  Verified: full `make sim_all` regression passes.

- [x] **blink_test.S loads 0xEFFF instead of 0xFFFF**
  Replaced `lui t1, 0x0000F` + `addi t1, t1, -1` with `addi t1, x0, -1`.
  `addi x0, x0, -1` sign-extends −1 to `0xFFFF_FFFF`; GPIO masks to [15:0] = `0xFFFF`.
  All 16 LEDs including LED[12] now light up correctly.

---

## P1 — High Priority Fixes

- [x] **Tighten MMIO address decode**
  Changed uart/timer/gpio_sel to check `dmem_addr[31:16] == 16'h4000` (was only [31:28] + [15:12]).
  Aliases like `0x4001_0000` and `0x4FFF_0000` no longer hit UART. Also updated
  `mmio_read_data_reg` capture condition to match. Verified: sim_all passes.

- [x] **Tighten DMEM address decode**
  Changed `dmem_sel` from `dmem_addr[31:28] == 4'h2` to `dmem_addr[31:14] == 18'h8000`.
  Now accepts only `0x2000_0000–0x2000_3FFF` (exact 16 KB window). Verified: sim_all passes.

- [x] **Rename `fetch_en` to `instr_latch_en`**
  Renamed consistently across `control_unit.sv`, `datapath.sv`, and `cpu.sv`.
  Fixed port comment to say "HIGH in STATE_DECODE — latches synchronous IMEM output".
  Verified: sim_all passes.

- [x] **Remove dead `alu_zero` input and `branch` output from control_unit**
  Removed `alu_zero` input from `control_unit.sv` and `datapath.sv` port lists (kept as
  internal wire for ALU wiring). Removed `branch` output from `control_unit.sv` and input
  from `datapath.sv`; removed `branch = 0/1` assignments; cleaned up `cpu.sv` wires and
  port maps. Verified: sim_all passes.

- [x] **Add reset to `alu_result_reg`**
  Added `if (!rst_n) alu_result_reg <= 32'b0` to the always_ff block in `datapath.sv`.
  Verified: sim_all passes.

- [x] **Fix GPIO direction register — implement it or remove the illusion**
  Changed `assign gpio_out = output_reg` to `assign gpio_out = output_reg & direction_reg`.
  Updated `tb_gpio.sv`: set direction=0xFFFF before Test 1; added direction-gating check
  (direction=0xAAAA, output=0xFF00 → gpio_out=0xAA00). Verified: sim_all passes.

- [x] **Add 2-FF synchronizer to GPIO inputs**
  Added `gpio_in_sync_0/sync` and `gpio_buttons_sync_0/sync` flip-flop chains in `gpio.sv`.
  Read logic now uses the synchronized signals. Updated `tb_gpio.sv` to clock 2 cycles
  after setting inputs before reading. Verified: sim_all passes.

- [x] **Parameterize UART baud counter width**
  Changed `tx_baud_counter` and `rx_baud_counter` from `logic [9:0]` to
  `logic [$clog2(BAUD_DIV)-1:0]`. Width auto-scales with clock/baud parameters.
  At 100 MHz/115200: still 10 bits (unchanged). At 9600 baud: 14 bits (was overflowing).
  Verified: sim_all passes.

- [x] **Fix CPI documentation**
  Updated `CLAUDE.md` with a per-class cycle-count table: branches 3, stores/ALU/jumps 4,
  loads 5, multiply 6, divide/remainder 38. Verified: sim_all passes.

- [x] **Add MULHSU and MULHU to the ISA diagnostic**
  Added 4 test cases (fail_54–57): MULHSU with negative a (-1×0xFFFFFFFF→-1), MULHSU with
  positive a (5×12→0), MULHU (0x80000000²→0x40000000), MULHU (0xFFFFFFFF²→0xFFFFFFFE).
  ISA diagnostic now covers 57 tests and passes in 997 cycles. Verified: sim_all passes.

- [x] **Fix timer polling contract in main.c**
  Replaced `timer_set(50000000)` + poll with `timer_clear()` + `timer_set(0xFFFFFFFF)` +
  poll until < 50000000. Counter resets to 0 and runs free (compare=max won't fire), so
  the poll is monotonically safe. Removed redundant `timer_clear()` at loop end.

- [x] **Fix duplicate UART access in soc_diag.c**
  Removed `uart_putc_word()` function entirely. `uart_emit_banner()` now calls `uart_putc()`
  from the driver. Verified: sim_soc_diag passes in 6369 cycles (unchanged behavior).

---

## P2 — Medium Priority (Complete SoC Demo)

- [x] **7-segment display peripheral**
  Added hardware-multiplexed 8-digit controller at `0x40003000`, scan rate CLK_FREQ/4000
  (4 kHz at both 50 MHz FPGA and 100 MHz simulation). CLK_FREQ driven by `UART_CLK_FREQ`
  parameter so it auto-scales with the SoC clock. Registers: DISPLAY (0x00, 32-bit hex
  value) and CONTROL (0x04, bit0=enable). Active-LOW anodes and segments match Nexys A7
  hardware. All 7 files created/modified: `rtl/peripheral/sevenseg.sv`,
  `rtl/soc_top.sv`, `rtl/nexys_a7_top.sv`, `constraints/nexys_a7.xdc`,
  `sw/drivers/sevenseg.{c,h}`, `docs/memory_map.md`, `tb/peripheral/tb_sevenseg.sv`,
  `Makefile`. Integration testbenches (`tb_soc_diag`, `tb_soc_top_decode`) updated.
  Verified: `sim_all` passes.

- [x] **Calculator demo firmware**
  `sw/tests/calculator.c` polls buttons with rising-edge detection (no blocking busy-wait).
  `SW[7:0]` → operand A, `SW[15:8]` → operand B; BTNU=add, BTNL=sub, BTNR=mul, BTND=div.
  Result shown on LEDs, 7-seg display, and UART as "AA op BB = RRRRRRRR\n".
  Integration testbench `tb/integration/tb_calculator.sv` covers 6 tests (ADD/MUL/SUB/DIV-by-zero/DIV/UART).
  Verified: `sim_calculator` passes all 12 checks; `sim_all` regression clean.

- [x] **`updatemem` Makefile target for fast bitstream patching**
  `make update_bitstream PROG=sw/tests/<name>.elf` patches IMEM in the existing bitstream
  without re-running synthesis. Validates that `.mmi` and `.bit` files exist before calling
  `updatemem`. `VIVADO_IMPL_DIR` defaults to `impl_1`, overridable on the command line.
  Documented in CLAUDE.md with Vivado environment-sourcing instructions.

- [x] **Fix testbench memory models to be synchronous**
  Replaced `assign imem_data` and `assign dmem_read_data` with `always_ff` registered reads
  in both `tb/core/tb_cpu.sv` and `tb/core/tb_cpu_regression.sv`. Models now match the one-
  cycle latency of the real `imem.sv` and `dmem.sv` BRAMs. Verified: sim_all passes.

- [x] **Fix tb_cpu_regression DMEM address space**
  Changed dmem array indexing from `dmem_addr[31:2]` to `dmem_addr[9:2]` (strips base),
  inserted `lui x5, 0x20000` before store/load so the test uses address `0x20000000`,
  updated JAL link expected value from 32 to 36 (JAL now at PC=0x20). Added `encode_u`
  helper. Verified: sim_cpu_regression passes; sim_all clean.

- [x] **Update docs/test_cases.md**
  Section 3 updated with calculator integration test; section 4 lists all compile_* targets;
  section 5 checklist updated with sim_calculator and update_bitstream workflow; section 6
  converted to "Resolved Bugs" audit table; section 7 reduced to 2 open P3 items (no CSRs,
  timer_interrupt unconnected).

- [x] **Add .gitignore entries for .mem build artifacts**
  Added `sw/tests/*.mem` to `.gitignore` with `!sw/tests/test_imem.mem` exception (static
  test fixture for tb_soc_top_decode). Ran `git rm --cached sw/tests/program.mem` to untrack
  the previously committed artifact. All generated `.mem` files now regenerated via `make compile_*`.

---

## P3 — Low Priority (Future Enhancements)

- [x] **Add basic CSR support**
  Added `rtl/core/csr_file.sv`: MSTATUS, MIE, MTVEC, MSCRATCH, MEPC, MCAUSE, MIP, MHARTID.
  Added STATE_TRAP (3'b110) to the FSM. ECALL traps in 4 cycles; timer IRQ traps in 2 cycles
  (FETCH→TRAP). MRET restores MIE from MPIE and returns to MEPC in STATE_EXECUTE (3 cycles).
  CSRRW/CSRRS/CSRRC and immediate variants fully implemented. Write-inhibit for rs1=x0
  (CSRRS/CSRRC). `csr_file.sv` instantiated in `datapath.sv`; new ports wired through
  `cpu.sv`. Unit-tested by `tb_csr.sv` (24 checks); integration-tested by `tb_cpu_csr.sv`
  (10 checks: ECALL/MRET + timer IRQ). Verified: sim_all passes.

- [x] **Connect timer interrupt through CPU**
  Wired `timer_interrupt` from `u_timer` to `u_cpu.irq_m_timer` via `timer_irq` logic wire
  in `rtl/soc_top.sv`. Previously left open. Verified: sim_all passes.

- [x] **Implement exception/trap handling**
  Added `mem_addr_misaligned` combinational signal in `datapath.sv` (funct3-gated check on
  `alu_result[1:0]`). Replaced 1-bit `trap_is_interrupt` with `trap_cause[31:0]` (full
  MCAUSE value) wired through `control_unit.sv → cpu.sv → datapath.sv → csr_file.sv`.
  Added `trap_val[31:0]` computed in `datapath.sv` (faulting address for misaligned,
  instruction word for illegal, zero otherwise) and forwarded to `csr_file.sv` as MTVAL.
  Added `is_valid_opcode` gate in `control_unit.sv`; STATE_EXECUTE `default` now goes to
  STATE_TRAP instead of STATE_WRITEBACK. Illegal instructions (0x2), load-misalign (0x4),
  store-misalign (0x6) all correctly trap, save MEPC/MCAUSE/MTVAL, and redirect to MTVEC.
  ISA diagnostic updated: removed 5 stale "align-down" tests (49–53) that relied on
  pre-exception silent masking; MULHSU/MULHU tests (54–57) unaffected.
  New integration testbench `tb/core/tb_cpu_exceptions.sv` covers all 3 fault types (21
  checks). Verified: sim_cpu_exceptions passes; full sim_all regression clean.

- [x] **Fix UART overrun: add RX FIFO or overrun flag**
  Added `rx_overrun` register in `rtl/peripheral/uart.sv`. In `RX_STOP`: if `rx_valid=1`
  when a new byte completes, `rx_overrun` is set (new byte still overwrites — latest data
  wins). Both `rx_valid` and `rx_overrun` clear when `RX_DATA` is read. STATUS[2] now
  exposes the flag. Added `UART_RX_OVERRUN (1<<2)` to `uart.h`; added `uart_overrun()`
  to `uart.c`. Updated `docs/memory_map.md`. 4 new testbench checks cover: flag set on
  second unread byte, valid stays 1, latest byte returned, both flags clear on read.
  Verified: sim_uart passes (12 checks); full sim_all regression clean.

- [x] **Pipeline MDU to close 100 MHz timing**
  Added `S_MUL_LOAD` state and `mul_a_reg/mul_b_reg [63:0]` registers to `rtl/core/mdu.sv`.
  S_IDLE now latches pre-extended 64-bit operands (sign/zero based on op type); S_MUL_LOAD
  computes `$signed(mul_a_reg) * $signed(mul_b_reg)` into `mul_full`. This breaks the
  old one-cycle `start → 64-bit multiply → register` path (WNS = -4.468 ns) into two
  registered stages — the critical stage is now reg→DSP→reg which Vivado can pipeline in
  DSP48E1 blocks at 100 MHz. Multiply latency: 7 cycles total (was 6). Divide unchanged.
  Removed the 50 MHz clock divider from `rtl/nexys_a7_top.sv` and updated UART_CLK_FREQ
  back to 100_000_000. Removed the generated-clock XDC constraint for the divider.
  CLAUDE.md CPI table updated (multiply: 7 cycles). Requires Vivado re-implementation to
  confirm timing closure at 100 MHz. Verified: all 20 sim_mdu checks pass; sim_all clean.

- [x] **UART bootloader + writable instruction memory**
  Added write port to `rtl/memory/imem.sv` (write_en, write_addr[11:0], write_data[31:0]).
  IMEM write window at `0x50000000–0x50003FFF` decoded in `soc_top.sv`; SW stores to this
  range write directly into IMEM instruction words. `PC_RESET` parameter propagates through
  `datapath → cpu → soc_top → nexys_a7_top` (default 0x0, FPGA overrides to 0x3C00).
  Bootloader binary at `sw/tests/bootloader.c` (159 words = 636 bytes; fits in top 1 KB of
  IMEM at 0x3C00–0x3FFF). User programs uploaded to words 0–3839 (15 KB) so bootloader is
  never overwritten by its own receive loop. Protocol: "BOOT\r\n" banner → 4-byte LE word
  count → word_count×4 bytes → "OK\r\n" → jump to 0x0. Host upload tool at
  `scripts/uart_upload.py`. Combined image builder at `scripts/make_boot_mem.py`.
  Linker: `sw/linker/linker_boot.ld` (text at 0x3C00, 1 KB limit).
  Build: `make compile_bootloader` → `sw/tests/bootloader.mem`.
  `tb/memory/tb_imem.sv` updated (write port tied to 0). Verified: `sim_all` clean (18 targets).

- [x] **Increase IMEM/DMEM to 32 KB each**
  Changed `IMEM_DEPTH` and `DMEM_DEPTH` defaults to 8192 (32 KB) in `imem.sv`, `dmem.sv`,
  and `soc_top.sv`. Updated address decode: `dmem_sel` → `[31:15]==17'h4000`
  (0x20000000–0x20007FFF), `imem_sel` → `[31:15]==17'h0` (0x00000000–0x00007FFF).
  IMEM write window expanded: `[31:15]==17'hA000` (0x50000000–0x50007FFF); `imem_write_addr`
  widened to 13 bits (`dmem_addr[14:2]`). Bootloader relocated from 0x3C00→0x7C00
  (PC_RESET updated in `nexys_a7_top.sv`; linker_boot.ld updated). MAX_WORDS in
  `bootloader.c` updated to 7936 (31 KB user area). `bin_to_mem.py` default padding updated
  to 8192 words (eliminates `$readmemh` warning). Linker scripts updated to 32KB.
  Verified: `sim_all` clean (18 targets, no warnings).

- [x] **Add formal properties (SVA)**
  Created `tb/core/tb_sva.sv` with 5 clocked immediate assertions (Icarus-compatible
  substitute for concurrent `assert property`):
    P1 — PC always word-aligned (`imem_addr[1:0] == 2'b00`)
    P2 — `dmem_write_en` and `dmem_read_en` mutually exclusive
    P3 — FSM state never equals 3'b111 (the one unreachable encoding)
    P4 — No DMEM access during STATE_FETCH or STATE_DECODE
    P5 — `dmem_write_en` never asserted with all byte enables off
  Testbench uses ISA diagnostic as stimulus witness (863 cycles, all 57 tests).
  Added `sim_sva` to `sim_all`. Updated `tb_cpu_isa_diag.sv` arrays to 8192 words.
  Verified: `sim_sva` passes with no warnings; `sim_all` clean (19 targets).

- [x] **MULHSU/MULHU negative-operand corner cases**
  Added fail_58: MULHSU(INT_MIN=0x80000000, 0xFFFFFFFF) → upper=0x80000000 (max-negative
  signed × max unsigned). Added fail_59: MULHSU(INT_MIN, 0) → 0 (operand_b=0 zero-product).
  ISA diagnostic now covers 59 tests and passes in 895 cycles. Verified: sim_all clean (19 targets).

---

## Completed

*(Move items here with `[x]` when done)*

---

## Files to Clean Up

- [x] Deleted `.codex` — empty file, no purpose
- [x] Deleted stale build artifacts from `sw/tests/`: `*.elf`, `*.bin`
- [x] Archived `CODES.md` → `docs/CODES.md`
- [x] Updated `docs/test_cases.md` — sections 6 and 7 now reflect actual open gaps

---

## FPGA Programming Reference

### One-time setup (after any RTL change)
1. `make compile_bootloader` (WSL) — builds `sw/tests/bootloader.mem`
2. Vivado: **Generate Bitstream** (XDC now sets `SPI_BUSWIDTH=4` and `CONFIGRATE=33`)
3. Vivado TCL console — generate .mcs:
   ```tcl
   write_cfgmem -format mcs -size 16 -interface SPIx4 \
     -loadbit "up 0x0 C:/Users/samet/Projects/risc-v-soc/vivado/risc-v-soc/risc-v-soc.runs/impl_1/nexys_a7_top.bit" \
     -file "C:/Users/samet/Projects/risc-v-soc/nexys_a7_top.mcs" -force
   ```
4. Hardware Manager: right-click **xc7a100t_0** → **Program Device** → select `nexys_a7_top.bit`
5. While FPGA is live: right-click **s25fl128s** → **Program Configuration Memory Device** → select `nexys_a7_top.mcs`
6. Unplug and replug — FPGA auto-configures, UART shows `BOOT`

> **Note:** Step 4 must happen before Step 5. Vivado needs the FPGA to be live to talk
> to the SPI flash (indirect programming via the `spi_xc7a100t_pullnone.bit` proxy,
> which in Vivado 2025.2 is only accessible when FPGA is already running).

### Firmware-only update (no RTL change)
```bash
make compile_soc_diag        # or compile_calculator, compile_irq_demo, etc.
python3 scripts/uart_upload.py sw/tests/soc_diag.bin
```
No Vivado needed. Bootloader saves to SPI flash; survives power cycles.

---

## Phase 5 — Compliance, Official Tests, and Final Polish (deadline June 1)

---

### Bugs — Found by reading current RTL (May 2026)

- [x] **EBREAK gets wrong MCAUSE**
  `control_unit.sv:156–160` — the `funct3==3'b000` branch sends both ECALL and EBREAK to
  STATE_TRAP with `trap_cause_reg = EXC_ECALL_M` (cause=11). EBREAK
  (`instruction[31:20]==12'h001`) must trap with MCAUSE=3 (breakpoint).
  **Fix:** added `EXC_EBREAK = 32'h3` to `riscv_pkg.sv`; in the `trap_cause_reg` always_ff
  block checks `instruction[31:20]`: `12'h001` → `EXC_EBREAK`, else → `EXC_ECALL_M`.
  Added Test 4 to `tb_cpu_exceptions.sv` (MCAUSE=3, MTVAL=0). All 30 checks pass.

- [x] **FENCE/FENCE.I treated as illegal instruction**
  FENCE opcode `7'b0001111` was absent from `is_valid_opcode` in `control_unit.sv`.
  **Fix:** added `OP_FENCE` to `riscv_pkg.sv` and `is_valid_opcode`; added
  `OP_FENCE: next_state = STATE_FETCH` and `OP_FENCE: begin alu_reg_en=0; pc_write_en=1; end`
  in STATE_EXECUTE. Added Test 5 to `tb_cpu_exceptions.sv` (FENCE NOP). All 30 checks pass.

- [x] **Instruction address misalignment not trapped**
  JALR and taken branches did not check bit[1] of the computed target, so a misaligned
  fetch target silently redirected the PC instead of raising MCAUSE=0.
  **Fix:** added `EXC_FETCH_MISALIGN = 32'h0` to `riscv_pkg.sv`; added `fetch_addr_misaligned`
  output to `datapath.sv` (checks bit[1] of JALR target or `pc_branch`); added `fetch_target`
  combinational signal for MTVAL; updated `control_unit.sv` next-state logic for OP_B/JAL/JALR;
  suppressed `pc_write_en` for taken branch to misaligned target so MEPC = branch PC; added
  Tests 6 (JALR) and 7 (branch) to `tb_cpu_exceptions.sv`. All 44 checks pass.
  In `datapath.sv`, add a combinational signal `fetch_addr_misaligned` that is HIGH when
  `pc_next[1]` is 1 during STATE_EXECUTE for OP_JALR or a taken OP_B.
  Wire it to `control_unit.sv`; redirect STATE_EXECUTE → STATE_TRAP when asserted.
  In the `trap_cause_reg` always_ff, set `EXC_FETCH_MISALIGN` for this case.
  Add test cases to `tb_cpu_exceptions.sv`.

---

### Official RISC-V Test Suite Integration

- [x] **Run the official riscv-tests against the CPU**
  48/48 tests pass (38 rv32ui + 8 rv32um + ma_data + simple). Custom `sw/riscv-tests/riscv_test.h`
  maps tohost to DMEM[0] (0x20000000). Testbench `tb/riscv-tests/tb_riscv_tests.sv` polls
  tohost; pass=1, fail=(N<<1)|1. `bin_to_mem.py` extended with `-d/--depth` flag; all targets
  use `-d 4096`. Hardware misaligned load/store implemented (STATE_MEMORY2, dmem_data_buf,
  barrel-shift byte enables in datapath.sv) so `ma_data` passes natively without trapping.
  `RVTEST_DATA_BEGIN` pads tohost to 8 bytes so ma_data's `.align 3` resolves correctly.
  `sim_riscv_tests` added to `sim_all`. Verified: `make sim_riscv_tests` → All riscv-tests passed.

---

### Performance Metrics

- [x] **Add RDCYCLE and RDINSTRET CSR support** ✓ DONE (2026-05-16)
  `mcycle_reg` increments every clock; `minstret_reg` increments via `instret_en`
  pulse from control_unit (= `pc_write_en && current_state != STATE_TRAP`).
  CSR_CYCLE=0xC00, CSR_INSTRET=0xC02 added to riscv_pkg.sv. All sim_all passes.

- [x] **Performance benchmark program** ✓ DONE (2026-05-16)
  `sw/tests/benchmark.c`: 1000 iterations of add+mul+divu+branch.
  Simulation results: 206124 cycles, 39030 instructions, CPI=5.2, MIPS=18.9 @ 100 MHz.
  Build: `make compile_benchmark`. Run: `make sim_benchmark`.

---

### Deliverable Documentation

- [ ] **Record Vivado timing and utilization reports**
  After the next synthesis run, capture and commit:
  - `docs/timing_report.txt` — worst negative slack (WNS), total negative slack (TNS),
    achieved Fmax. If WNS ≥ 0 ns at 100 MHz: write "timing closure achieved at 100 MHz."
  - `docs/utilization_report.txt` — LUT count and % of XC7A100T total (101K LUTs),
    flip-flop count, BRAM count (should be 4 × 36Kb for 32 KB IMEM + 32 KB DMEM),
    DSP48 count (should be 2–4 for the pipelined MDU multiplier).
  These numbers directly answer the proposal evaluation criteria (Fmax, resource utilization).

- [x] **Interrupt-driven UART demo firmware** ✓ DONE (2026-05-16)
  `sw/tests/irq_demo.c`: MTVEC→ISR, MIE.MTIE, timer 0.5s (hardware) / 500 clocks (SIM_MODE).
  ISR toggles LED[15], increments counter, updates 7-seg. Main loop echoes UART.
  Fixed timer.sv: one-cycle pulse → sticky irq_flag (cleared by SW write to TIMER_STATUS).
  sim_irq_demo passes: ISR fires 3×, LED[15] toggles, 7-seg non-zero.
