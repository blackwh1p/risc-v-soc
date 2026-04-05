// ============================================================
// Module  : alu
// Purpose : Arithmetic Logic Unit for RV32IM
//           Performs all arithmetic, logic, shift, and
//           comparison operations for the CPU core.
// ============================================================

import alu_ops::*;

module alu (
    // Operation select — tells the ALU what to do
    // Encoding will be defined in a separate parameters file
    input  logic [3:0]  operation,

    // Two 32-bit input operands
    input  logic [31:0] operand_a,   // usually the value from a register
    input  logic [31:0] operand_b,   // register value or immediate

    // 32-bit result output
    output logic [31:0] result,

    // Zero flag — goes HIGH when result == 0
    // Used by branch instructions (BEQ, BNE, etc.)
    output logic        zero
);

    // Extract shift amount outside always_comb for Icarus compatibility
    logic [4:0] shamt;
    assign shamt = operand_b[4:0];

    // Force Vivado to use DSP48E1 hardware multiplier blocks (Artix-7 has 240).
    // Without this, Vivado builds the 32x32 multiply from ~283 CARRY4 LUT chains
    // (~98 ns) which violates the 10 ns clock. DSP48E1 completes it in ~4-5 ns.
    (* use_dsp = "yes" *) logic [63:0] mul_result;
    (* use_dsp = "yes" *) logic [31:0] div_result;
    (* use_dsp = "yes" *) logic [31:0] divu_result;
    (* use_dsp = "yes" *) logic [31:0] rem_result;
    (* use_dsp = "yes" *) logic [31:0] remu_result;

    assign mul_result = $signed(operand_a) * $signed(operand_b);
    assign div_result  = $signed(operand_a) / $signed(operand_b);
    assign rem_result  = $signed(operand_a) % $signed(operand_b);
    assign divu_result = operand_a / operand_b;
    assign remu_result = operand_a % operand_b;

    always_comb begin
        case (operation)
            ALU_ADD:    result = operand_a + operand_b;
            ALU_SUB:    result = operand_a - operand_b;
            ALU_AND:    result = operand_a & operand_b;
            ALU_OR:     result = operand_a | operand_b;
            ALU_XOR:    result = operand_a ^ operand_b;
            ALU_SLL:    result = operand_a << shamt;
            ALU_SRL:    result = operand_a >> shamt;
            ALU_SRA:    result = $signed(operand_a) >>> shamt;
            ALU_SLT:    result = {31'b0, ($signed(operand_a) < $signed(operand_b))};
            ALU_SLTU:   result = {31'b0, (operand_a < operand_b)};
            ALU_MUL:    result = mul_result[31:0];
            ALU_MULH:   result = mul_result[63:32];
            ALU_DIV:    result = div_result;
            ALU_DIVU:   result = divu_result;
            ALU_REM:    result = rem_result;
            ALU_REMU:   result = remu_result;
            default:    result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0) ? 1'b1 : 1'b0;

endmodule