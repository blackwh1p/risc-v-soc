# Custom RISC-V SoC — RV32IM on Nexys A7

A custom RISC-V System-on-Chip (SoC) implemented in SystemVerilog, targeting the
Digilent Nexys A7 FPGA board. The processor implements the RV32IM ISA
(base integer instruction set + multiply/divide extension) as a multi-cycle
finite-state machine, with a minimal bare-metal software stack.

---

## Project Structure
```
risc-v-soc/
├── rtl/                  # SystemVerilog RTL source files
│   ├── core/             # CPU core (ALU, register file, FSM, datapath)
│   ├── memory/           # Instruction and data memory (BRAM)
│   └── peripheral/       # UART, Timer, GPIO
├── tb/                   # Simulation testbenches
│   ├── core/
│   ├── memory/
│   └── peripheral/
├── sw/                   # Bare-metal software
│   ├── startup/          # crt0.S — reset/startup code
│   ├── drivers/          # C peripheral drivers
│   ├── tests/            # Test programs
│   └── linker/           # Linker script
├── constraints/          # Nexys A7 XDC pin constraints
├── scripts/              # Build helper scripts
├── docs/                 # Memory map, register map, block diagrams
└── Makefile              # Top-level build system
```

---

## Hardware Target

| Item | Detail |
|------|--------|
| Board | Digilent Nexys A7-100T |
| FPGA | Xilinx Artix-7 XC7A100T |
| HDL | SystemVerilog |
| ISA | RISC-V RV32IM |
| Implementation | Multi-cycle FSM |

---

## Toolchain

| Tool | Purpose |
|------|---------|
| Xilinx Vivado 2023.2 | Synthesis, implementation, FPGA programming |
| Icarus Verilog + GTKWave | RTL simulation and waveform viewing |
| Verilator | Fast cycle-accurate simulation for ISA tests |
| riscv64-unknown-elf-gcc | Cross-compiler for bare-metal C and Assembly |

---

## Key References

- [RISC-V Unprivileged ISA Specification](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)
- [RISC-V Privileged ISA Specification](https://github.com/riscv/riscv-isa-manual/releases/download/Priv-v1.12/riscv-privileged-20211203.pdf)
- [Nexys A7 Reference Manual](https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual)
- [riscv-tests — Official ISA Test Suite](https://github.com/riscv-software-src/riscv-tests)

---

## Build and Simulate
```bash
# Simulate ALU (available after Week 3)
make sim_alu

# Compile test software
make compile_sw

# Clean all generated files
make clean
```

---

## Development Roadmap

| Phase | Weeks | Milestone |
|-------|-------|-----------|
| 0 | — | Toolchain setup, repo initialization |
| 1 | 1–2 | Architecture design, memory map, port declarations |
| 2 | 3–4 | Multi-cycle RV32IM core + ISA regression tests |
| 3 | 5–6 | BRAM memory + UART/Timer/GPIO peripherals |
| 4 | 7–8 | Bare-metal software stack + FPGA boot demo |
| 5 | 9–10 | Verification, FPGA metrics, documentation |

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

The RISC-V ISA specification is © RISC-V International, licensed under
Creative Commons Attribution 4.0. This repository contains an original
implementation and is not a derivative of the specification document.
