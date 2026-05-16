// ============================================================
// File    : alu_ops.sv
// Purpose : ALU operation code definitions
//           Shared parameters used by ALU and control unit
// ============================================================

package alu_ops;

    parameter logic [4:0] ALU_ADD    = 5'd0;   // Addition
    parameter logic [4:0] ALU_SUB    = 5'd1;   // Subtraction
    parameter logic [4:0] ALU_AND    = 5'd2;   // AND Operation
    parameter logic [4:0] ALU_OR     = 5'd3;   // OR Operation
    parameter logic [4:0] ALU_XOR    = 5'd4;   // XOR Operation
    parameter logic [4:0] ALU_SLL    = 5'd5;   // Shift Left Logical
    parameter logic [4:0] ALU_SRL    = 5'd6;   // Shift Right Logical
    parameter logic [4:0] ALU_SRA    = 5'd7;   // Shift Right Arithmetic
    parameter logic [4:0] ALU_SLT    = 5'd8;   // Set Less Than Signed
    parameter logic [4:0] ALU_SLTU   = 5'd9;   // Set Less Than Unsigned

    // RV32M Extension
    parameter logic [4:0] ALU_MUL    = 5'd10;  // Multiply (lower 32 bits), signed×signed
    parameter logic [4:0] ALU_MULH   = 5'd11;  // Multiply high, signed×signed
    parameter logic [4:0] ALU_MULHSU = 5'd12;  // Multiply high, signed×unsigned
    parameter logic [4:0] ALU_MULHU  = 5'd13;  // Multiply high, unsigned×unsigned
    parameter logic [4:0] ALU_DIV    = 5'd14;  // Divide signed
    parameter logic [4:0] ALU_DIVU   = 5'd15;  // Divide unsigned
    parameter logic [4:0] ALU_REM    = 5'd16;  // Remainder signed
    parameter logic [4:0] ALU_REMU   = 5'd17;  // Remainder unsigned

endpackage