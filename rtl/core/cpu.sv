// ============================================================
// Module  : cpu
// Purpose : Top-level RV32IM CPU core
//           Instantiates and connects control_unit and datapath
// ============================================================
module cpu (
    input  logic        clk,
    input  logic        rst_n,

    // Instruction memory interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_data,

    // Data memory interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_write_data,
    output logic        dmem_write_en,
    output logic        dmem_read_en,
    input  logic [31:0] dmem_read_data
);

    // Internal logic will be added in Phase 2

endmodule