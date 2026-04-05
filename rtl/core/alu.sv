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

    logic [63:0] mul_result;
    assign mul_result = $signed(operand_a) * $signed(operand_b);

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
            ALU_DIV:    result = $signed(operand_a) / $signed(operand_b);
            ALU_DIVU:   result = operand_a / operand_b;
            ALU_REM:    result = $signed(operand_a) % $signed(operand_b);
            ALU_REMU:   result = operand_a % operand_b;
            default:    result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0) ? 1'b1 : 1'b0;

endmodule