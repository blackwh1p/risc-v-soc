// ============================================================
// Module  : alu
// Purpose : Arithmetic Logic Unit for RV32IM
//           Performs all arithmetic, logic, shift, and
//           comparison operations for the CPU core.
// ============================================================
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

    // Internal logic will be added in Phase 2

endmodule