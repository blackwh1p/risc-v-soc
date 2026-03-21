// ============================================================
// Module  : datapath
// Purpose : CPU datapath for RV32IM multi-cycle implementation
//           Connects PC, register file, ALU, immediate generator,
//           and memory interfaces
// ============================================================
module datapath (
    input  logic        clk,
    input  logic        rst_n,

    // Control signals from control unit
    input  logic [3:0]  alu_operation,
    input  logic        alu_src_b,
    input  logic        reg_write,
    input  logic        mem_to_reg,
    input  logic        branch,
    input  logic        jump,
    input  logic [1:0]  pc_src,

    // Instruction memory interface
    output logic [31:0] imem_addr,      // address sent to instruction memory
    input  logic [31:0] imem_data,      // instruction received from memory

    // Data memory interface
    output logic [31:0] dmem_addr,      // address sent to data memory
    output logic [31:0] dmem_write_data,// data to write to memory
    output logic        dmem_write_en,  // write enable signal
    output logic        dmem_read_en,   // read enable signal
    input  logic [31:0] dmem_read_data, // data read from memory

    // Status signals to control unit
    output logic [31:0] instruction,    // current instruction
    output logic        alu_zero        // zero flag from ALU
);

    // Internal logic will be added in Phase 2

endmodule