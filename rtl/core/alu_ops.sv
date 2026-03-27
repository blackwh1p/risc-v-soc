// ============================================================
// File    : alu_ops.sv
// Purpose : ALU operation code definitions
//           Shared parameters used by ALU and control unit
// ============================================================

package alu_ops;

    parameter logic [3:0] ALU_ADD   = 4'b0000;  // Addition
    parameter logic [3:0] ALU_SUB   = 4'b0001;  // Subtraction
    parameter logic [3:0] ALU_AND   = 4'b0010;  // AND Operation
    parameter logic [3:0] ALU_OR    = 4'b0011;  // OR Operation
    parameter logic [3:0] ALU_XOR   = 4'b0100;  // XOR Operation
    parameter logic [3:0] ALU_SLL   = 4'b0101;  // Shift Left Logical
    parameter logic [3:0] ALU_SRL   = 4'b0110;  // Shift Right Logical
    parameter logic [3:0] ALU_SRA   = 4'b0111;  // Shift Right Arithmetic
    parameter logic [3:0] ALU_SLT   = 4'b1000;  // Set Less Than Signed
    parameter logic [3:0] ALU_SLTU  = 4'b1001;  // Set Less Than Unsigned

endpackage