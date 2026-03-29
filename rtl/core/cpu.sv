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

    // Internal wires connecting control unit and datapath

    logic [31:0] instruction;
    logic        alu_zero;
    logic [3:0]  alu_operation;
    logic        alu_src_b;
    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        branch;
    logic        jump;
    logic [1:0]  pc_src;
    logic        fetch_en;
    logic        pc_write_en;
    logic        alu_reg_en;

    control_unit u_control_unit (
    .clk            (clk),
    .rst_n          (rst_n),
    .instruction    (instruction),
    .alu_zero       (alu_zero),
    .alu_operation  (alu_operation),
    .alu_src_b      (alu_src_b),
    .reg_write      (reg_write),
    .mem_read       (mem_read),
    .mem_write      (mem_write),
    .mem_to_reg     (mem_to_reg),
    .branch         (branch),
    .jump           (jump),
    .pc_src         (pc_src),
    .fetch_en       (fetch_en),
    .pc_write_en    (pc_write_en),
    .alu_reg_en     (alu_reg_en)
    );

    datapath u_datapath (
    .clk            (clk),
    .rst_n          (rst_n),
    .alu_operation  (alu_operation),
    .alu_src_b      (alu_src_b),
    .reg_write      (reg_write),
    .mem_to_reg     (mem_to_reg),
    .branch         (branch),
    .jump           (jump),
    .pc_src         (pc_src),
    .imem_addr          (imem_addr),
    .imem_data          (imem_data),
    .dmem_addr          (dmem_addr),
    .dmem_write_data    (dmem_write_data),
    .dmem_write_en      (dmem_write_en),
    .dmem_read_en       (dmem_read_en),
    .dmem_read_data     (dmem_read_data),
    .instruction    (instruction),
    .alu_zero       (alu_zero),
    .fetch_en       (fetch_en),
    .pc_write_en    (pc_write_en),
    .alu_reg_en     (alu_reg_en)
    );

endmodule