# CODES

## Scope

This review was based on:

- `README.md`
- `CLAUDE.md`
- `docs/memory_map.md`
- `constraints/nexys_a7.xdc`
- startup/linker support files for software context

I also ran:

- `make sim_all`
- `make compile_sw`

Initial result: all supplied RTL and software-backed simulations passed in Icarus Verilog, and the bare-metal software compiled successfully. Later Vivado synthesis/implementation reports were inspected; those findings are recorded in the bring-up update below.

## Vivado Bring-Up Update

This section records the FPGA project/debug changes made after the initial review.

- `rtl/soc_top.sv` now defaults `IMEM_FILE` to `soc_diag.mem` instead of a repo-relative path. Vivado resolves `$readmemh` paths from the project/run context, so the matching `soc_diag.mem` file must be added to the Vivado project as a memory initialization file.
- `rtl/nexys_a7_top.sv` now explicitly overrides `IMEM_FILE` with `soc_diag.mem`, so the board build boots the full SoC diagnostic image rather than `test_imem.mem`.
- The routed 100 MHz implementation failed setup timing: `WNS = -4.468 ns`, `TNS = -597.759 ns`, with 224 failing endpoints. The worst paths are through the RV32M MDU multiplier DSP cascade, starting from the CPU control FSM/decode path and ending at MDU `mul_full` DSP inputs.
- Routing itself was clean: all routable nets were fully routed, with no route errors. Utilization was also low, so the timing failure is architectural, not a congestion or capacity issue.
- The correct long-term 100 MHz fix is to pipeline or restructure the MDU multiplier. A false path would be incorrect because the path is real synchronous logic.
- For first FPGA bring-up, option 1 has been applied: `rtl/nexys_a7_top.sv` divides the Nexys A7 100 MHz oscillator by two, feeds the SoC with a 50 MHz clock, and overrides `UART_CLK_FREQ` to `50_000_000` so the UART baud divider remains correct.
- `constraints/nexys_a7.xdc` keeps the board oscillator constrained as 100 MHz and adds a generated-clock constraint for the 50 MHz SoC clock. This avoids lying to Vivado by simply changing the input clock period to 20 ns.

## Bottom Line

The project is already in decent shape for a simple Nexys A7 demo. The CPU, memories, peripherals, startup code, drivers, and diagnostic software are coherent, and the supplied regression suite is good enough to show that the main datapaths basically work.

It is not yet fully hardened for FPGA use as a robust SoC. The biggest weaknesses are:

1. **Resolved for the current Vivado bring-up: the FPGA image previously booted the wrong program by default.**  
   `rtl/soc_top.sv` and `rtl/nexys_a7_top.sv` now select `soc_diag.mem`, but the `.mem` file still needs to be present in the Vivado project as a memory initialization file.

2. **Address decode aliases large reserved regions instead of rejecting them.**  
   `rtl/soc_top.sv:54-58` only checks top nibbles for DMEM/MMIO decode. For example, `dmem_sel` accepts any `0x2_______` address, not only `0x2000_0000-0x2000_3FFF`. That means bad addresses can silently hit real memory/peripherals.

3. **`main.c` uses the timer in a fragile way.**  
   `sw/tests/main.c:26-29` polls until `timer_read() < 50000000` becomes false, but `rtl/peripheral/timer.sv:41-46` resets the counter to zero when it reaches `compare_reg`. Because the compare value exists for only one cycle, software can miss it and loop forever or show unstable timing.

4. **GPIO direction is cosmetic, not functional.**  
   `rtl/peripheral/gpio.sv:24-25`, `37-38`, and `58` store a direction register but never use it to gate output or input behavior. For the current LED/switch demo this is acceptable, but it is misleading as a general GPIO block.

5. **GPIO inputs are unsynchronized and undebounced.**  
   `rtl/peripheral/gpio.sv:51` exposes raw buttons/switches directly, while `constraints/nexys_a7.xdc:69-73` only declares false paths. On FPGA this can produce bounce and occasional metastability around read timing.

6. **The UART is usable for demos, but not robust yet.**  
   `rtl/peripheral/uart.sv:29`, `34`, `45-46` fix the baud counters at 10 bits even though the module is parameterized, and `rtl/peripheral/uart.sv:147-191` only buffers one received byte with no overrun flag.

7. **Misaligned accesses are silently rounded down instead of trapping.**  
   `rtl/core/datapath.sv:253-263` aligns halfword and word accesses down to the nearest legal boundary. That is simple, but it is non-standard behavior and can hide software bugs.

8. **Illegal or unsupported instructions do not trap.**  
   `rtl/core/control_unit.sv:227-245` and `260-281` let many unknown cases fall through the default ALU/writeback path. For tightly controlled test code this is manageable, but for a more complete SoC it is a weakness.

9. **Some CPU-level benches use unrealistic memory models.**  
   `tb/core/tb_cpu.sv:53-61` and `tb/core/tb_cpu_regression.sv:48-60` use combinational memory reads, while the real SoC memories are synchronous. The integration benches help cover this, but the unit benches can still hide timing mistakes.

## Overall Sufficiency

### Sufficient right now

- RV32IM multi-cycle CPU demo
- BRAM-backed instruction/data memory
- Basic UART transmit/receive
- LED and switch demo on Nexys A7
- Bare-metal startup and simple firmware tests
- End-to-end simulation-based diagnostics

### Not sufficient yet if your goal is a more complete FPGA SoC

- No interrupt/trap/CSR path connected to the CPU
- No illegal-instruction or misaligned-access exception handling
- No synthesis/timing proof in Vivado yet
- No hardened GPIO input synchronization/debounce
- No robust timer software contract
- No strict reserved-region protection in the address decoder

## File-By-File Review

Headers (`.h`), assembly (`.S`), linker (`.ld`), and scripts were also read for context, but the table below focuses on the `.sv` and `.c` files you asked for.

### RTL and Software

| File | What it does | Assessment |
|---|---|---|
| `rtl/core/alu_ops.sv` | Defines ALU/MDU operation encodings shared by the core. | Sufficient and clean. Good centralization of opcodes. |
| `rtl/core/riscv_pkg.sv` | Defines RISC-V opcodes, funct fields, and FSM state encodings. | Sufficient for the current RV32IM subset. Fine for this project scope. |
| `rtl/core/alu.sv` | Pure combinational RV32I ALU. | Good and simple. M-extension ops are intentionally excluded and delegated to `mdu.sv`, which is the right choice for FPGA timing. |
| `rtl/core/mdu.sv` | Multi-cycle multiply/divide/remainder unit for RV32M. | One of the stronger files. The state machine and RV32M corner-case handling look solid, and simulation coverage is good. |
| `rtl/core/imm_gen.sv` | Generates sign/zero-extended immediates for I/S/B/U/J formats. | Sufficient and straightforward. No obvious issue. |
| `rtl/core/register_file.sv` | 32x32 register file with async reads and sync writes. | Sufficient for FPGA inference and for this CPU style. No reset is fine because software should not depend on register power-up state. |
| `rtl/core/control_unit.sv` | Multi-cycle controller for fetch/decode/execute/memory/writeback/MDU wait. | Mostly good, but unsupported instructions currently degrade into default behavior instead of trapping. Also `fetch_en` comment and actual use do not match. |
| `rtl/core/datapath.sv` | PC, instruction register, ALU/MDU path, register file, memory access path, load/store formatting. | Core datapath is coherent and passes regressions. The main weakness is the deliberate silent alignment of misaligned halfword/word accesses. |
| `rtl/core/cpu.sv` | Thin wrapper connecting control and datapath. | Sufficient. Clean integration layer. |
| `rtl/memory/imem.sv` | Synchronous ROM-like instruction memory with a second read port for IMEM-as-data reads. | Reasonable for current use. Good for simulation; actual BRAM inference should still be checked in Vivado. |
| `rtl/memory/dmem.sv` | Synchronous byte-enable data RAM. | Sufficient for the demo SoC. Again, final BRAM inference/timing still needs Vivado confirmation. |
| `rtl/peripheral/gpio.sv` | MMIO GPIO block for LEDs, switches, and buttons. | Works for the board demo, but it is weaker than its register model suggests: direction is not enforced, and raw async inputs are exposed directly. |
| `rtl/peripheral/timer.sv` | MMIO timer with compare and optional interrupt output. | Works in simulation, but the software contract is weak: it counts up, auto-wraps at compare, and the interrupt is not connected to the CPU. The header comment says “countdown” even though the implementation increments. |
| `rtl/peripheral/uart.sv` | MMIO UART TX/RX with baud divider and RX synchronizer. | Good enough for bring-up and demos. Weak points are the 10-bit fixed counters, single-byte RX buffering, and lack of overrun reporting. |
| `rtl/soc_top.sv` | Integrates CPU, memories, GPIO, timer, UART, and MMIO read mux. | Important file and mostly correct, but it contains two serious FPGA bring-up issues: wrong default IMEM image and overly broad address decode. |
| `rtl/nexys_a7_top.sv` | Board-level wrapper with reset synchronization and Nexys A7 ports. | Good wrapper. Reset handling is much better here than if `soc_top` were used directly. It should probably override `IMEM_FILE` for a real bitstream. |
| `sw/drivers/gpio.c` | Minimal MMIO driver for GPIO direction/output/input. | Sufficient for simple firmware. It matches the current hardware, although the hardware direction register is weaker than the API suggests. |
| `sw/drivers/timer.c` | Minimal MMIO driver for timer set/clear/read. | Usable, but too thin for a real delay API because it does not define wrap/match semantics clearly and does not expose interrupt mode. |
| `sw/drivers/uart.c` | Blocking MMIO UART driver for putc/puts/getc. | Fine for bare-metal diagnostics and bring-up. Not suitable for high-throughput or interrupt-driven use. |
| `sw/tests/main.c` | Demo firmware: prints banner, enables LEDs, waits using timer, toggles LEDs, prints “Tick!”. | Not fully sufficient as a hardware demo because the timer polling logic is fragile against the current timer design. This is the main software bug I would fix before FPGA bring-up. |
| `sw/tests/soc_diag.c` | Full SoC diagnostic firmware that checks startup/data/BSS/stack/DMEM/GPIO/timer/UART and reports signatures. | Strong test program. This is currently the best software image to use for FPGA validation. |

### Testbenches

| File | What it does | Assessment |
|---|---|---|
| `tb/core/tb_alu.sv` | Directed smoke tests for the ALU. | Good basic coverage for ALU ops. Still only directed testing, not exhaustive. |
| `tb/core/tb_mdu.sv` | Directed unit tests for multiply/divide/remainder including corner cases. | Strong bench. One of the better verification files in the repo. |
| `tb/core/tb_register_file.sv` | Tests register writes, readback, x0 protection, write enable. | Sufficient smoke test. |
| `tb/core/tb_cpu.sv` | Tiny CPU integration test with a simple fake program. | Useful as a smoke test only. Weak because both instruction and data memories are modeled as combinational reads. |
| `tb/core/tb_cpu_regression.sv` | Broader CPU smoke test for arithmetic, load/store, branch, and jump behavior. | Valuable regression, but still uses a simplified memory model that is easier than the real SoC. |
| `tb/core/tb_cpu_isa_diag.sv` | Runs compiled ISA diagnostic software on the CPU and checks pass/fail signatures in DMEM. | Good higher-level regression and much more meaningful than pure directed unit tests. |
| `tb/memory/tb_imem.sv` | Reads known words from initialized instruction memory. | Fine as a smoke test, but very narrow. It does not stress the second read port much. |
| `tb/memory/tb_dmem.sv` | Tests word write/read, one byte-write case, and read-enable hold behavior. | Acceptable smoke bench. Coverage is limited; halfword behavior and more alignment cases would still be worth testing. |
| `tb/peripheral/tb_uart.sv` | Tests UART TX start/complete path and RX valid/data behavior. | Good practical bench for a simple UART. It does not cover overrun or baud-configuration corner cases. |
| `tb/peripheral/tb_timer.sv` | Tests counter progress, compare wrap, interrupt pulse, and disable behavior. | Useful, but it validates the current wrap-on-compare design rather than judging whether that design is ideal for software. |
| `tb/peripheral/tb_gpio.sv` | Tests GPIO output write, input read, direction register readback, and reset. | Good for what the current block actually does. It does not catch that direction has no effect on outputs. |
| `tb/integration/tb_soc_top_decode.sv` | Tests top-level region select signals and read-data mux routing. | Good targeted decode bench. It does not test out-of-range aliasing, which is the real weakness in the decoder. |
| `tb/integration/tb_soc_diag.sv` | Full-SoC integration test using compiled diagnostic software, checking DMEM signatures, UART banner, and LEDs. | Strongest end-to-end bench in the repo. This gives the best confidence before FPGA bring-up. |

## My Practical Recommendation For FPGA Bring-Up

If your immediate goal is “get it running on Nexys A7,” the project is close enough. I would do these first:

1. Done for current bring-up: the FPGA build now selects `soc_diag.mem`, not `test_imem.mem`.
2. Fix the timer/software contract:
   either make the timer free-running and compare-only, or change the software to poll for wrap/status instead of polling for a single compare value.
3. Tighten address decode to exact documented regions.
4. Add synchronizers or sampling/debounce for switches/buttons if you will rely on them on real hardware.
5. Rerun Vivado synthesis/implementation and confirm timing closure at the temporary 50 MHz SoC clock. Treat 100 MHz closure as a later MDU pipeline/restructure task.

## Final Verdict

For simulation and a controlled demo, the codebase is largely sufficient.

For dependable FPGA use, the design still has a few real weak points. The two issues I would treat as highest priority are:

- the default FPGA image booting `test_imem.mem` if the current `soc_diag.mem` changes are not kept in the Vivado project
- the timer behavior versus the polling loop in `main.c`

Those are the most likely things to make the board behave differently from what you expect even though the current simulations are passing.
