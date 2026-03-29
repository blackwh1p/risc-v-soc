# ============================================================
# Project : Custom RISC-V SoC (RV32IM)
# Board   : Digilent Nexys A7
# HDL     : SystemVerilog
# ============================================================

# --- Cross-compiler toolchain prefix ---
# We use the 64-bit toolchain with 32-bit flags.
# riscv64-unknown-elf-gcc supports both 32 and 64 bit targets.
CROSS_COMPILE  = riscv64-unknown-elf
CC             = $(CROSS_COMPILE)-gcc
OBJCOPY        = $(CROSS_COMPILE)-objcopy
OBJDUMP        = $(CROSS_COMPILE)-objdump

# --- Compiler flags ---
# -march=rv32im  : target the RV32I base ISA + M (multiply) extension
# -mabi=ilp32    : 32-bit ABI, integers and pointers are 32 bits wide
# -nostdlib      : do not link the standard C library (no OS, no malloc/printf)
# -nostartfiles  : do not use default startup code (we write our own crt0.S)
# -g             : include debug symbols (useful for simulation inspection)
CFLAGS         = -march=rv32im -mabi=ilp32 -nostdlib -nostartfiles -g

# --- Simulator tools ---
IVERILOG       = iverilog
VVP            = vvp
GTKWAVE        = gtkwave

# --- Directory shortcuts ---
RTL_DIR        = rtl
TB_DIR         = tb
SW_DIR         = sw

# --- Default target ---
# Runs when you type 'make' with no arguments
.PHONY: all
all:
	@echo "================================================"
	@echo " RISC-V SoC Build System"
	@echo "================================================"
	@echo " Available targets:"
	@echo "   make sim_alu      - Simulate the ALU module"
	@echo "   make compile_sw   - Compile test software"
	@echo "   make clean        - Remove all generated files"
	@echo "================================================"

# --- Simulation targets (will be filled in as modules are built) ---

# --- Clean up all generated files ---
.PHONY: clean
clean:
	rm -f *.vvp *.vcd *.fst *.lxt
	rm -f *.elf *.bin *.hex *.map
	rm -f *.o *.a
	@echo "Clean complete."

# --- ALU Simulation ---
sim_alu:
	iverilog -g2012 -o sim_alu.vvp \
		rtl/core/alu_ops.sv \
		rtl/core/alu.sv \
		tb/core/tb_alu.sv
	vvp sim_alu.vvp

# --- Register File Simulation ---
sim_regfile:
	iverilog -g2012 -o sim_regfile.vvp \
		rtl/core/register_file.sv \
		tb/core/tb_register_file.sv
	vvp sim_regfile.vvp

# --- CPU Integration Simulation ---
sim_cpu:
	iverilog -g2012 -o sim_cpu.vvp \
		rtl/core/alu_ops.sv \
		rtl/core/riscv_pkg.sv \
		rtl/core/alu.sv \
		rtl/core/register_file.sv \
		rtl/core/imm_gen.sv \
		rtl/core/control_unit.sv \
		rtl/core/datapath.sv \
		rtl/core/cpu.sv \
		tb/core/tb_cpu.sv
	vvp sim_cpu.vvp