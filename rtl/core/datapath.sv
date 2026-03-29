// ============================================================
// Module  : datapath
// Purpose : CPU datapath for RV32IM multi-cycle implementation
//           Connects PC, register file, ALU, immediate generator
// ============================================================

import riscv_pkg::*;
import alu_ops::*;

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
    input  logic        fetch_en,
    input  logic        pc_write_en,
    input  logic        alu_reg_en,

    // Instruction memory interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_data,

    // Data memory interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_write_data,
    output logic        dmem_write_en,
    output logic        dmem_read_en,
    input  logic [31:0] dmem_read_data,

    // Status signals to control unit
    output logic [31:0] instruction,
    output logic        alu_zero
);

    // --------------------------------------------------------
    // Internal signals
    // --------------------------------------------------------
    logic [31:0] pc;              // current program counter
    logic [31:0] pc_next;         // next program counter value
    logic [31:0] pc_plus4;        // PC + 4
    logic [31:0] pc_branch;       // PC + immediate (branch/JAL target)
    logic [31:0] imm;             // sign-extended immediate
    logic [31:0] rs1_data;        // register file read port 1
    logic [31:0] rs2_data;        // register file read port 2
    logic [31:0] alu_operand_b;   // ALU second operand (reg or imm)
    logic [31:0] alu_result;      // ALU output
    logic [31:0] alu_result_reg;  // holds ALU result between EXECUTE and WRITEBACK
    logic [31:0] write_back_data; // data to write to register file
    logic [4:0]  rs1;             // source register 1 index
    logic [4:0]  rs2;             // source register 2 index
    logic [4:0]  rd;              // destination register index

    // --------------------------------------------------------
    // Instruction register
    // Captures instruction from memory during FETCH state
    // --------------------------------------------------------
    logic [31:0] instr_reg;

    always_ff @(posedge clk) begin
        if (!rst_n)
            instr_reg <= 32'b0;
        else if (fetch_en)
            instr_reg <= imem_data;
    end

    assign instruction = instr_reg;

    // --------------------------------------------------------
    // Instruction field extraction
    // --------------------------------------------------------
    assign rs1 = instr_reg[19:15];
    assign rs2 = instr_reg[24:20];
    assign rd  = instr_reg[11:7];

    // --------------------------------------------------------
    // Program Counter
    // --------------------------------------------------------

    always_ff @(posedge clk) begin
        if (alu_reg_en)
            alu_result_reg <= alu_result;
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            pc <= 32'b0;
        else if (pc_write_en)
            pc <= pc_next;
    end

    // PC + 4 calculation
    assign pc_plus4  = pc + 32'd4;

    // Branch/JAL target = PC + immediate
    assign pc_branch = pc + imm;

    always @(*) begin
        case (pc_src)
            2'b00: begin
                pc_next = pc_plus4;
            end
            2'b01: begin
                pc_next = pc_branch;
            end
            2'b10: begin
                pc_next = rs1_data + imm;
            end
            default: begin
                pc_next = pc_plus4;
            end
        endcase
    end

    // Connect PC to instruction memory address
    assign imem_addr = pc;

    // --------------------------------------------------------
    // Submodule instantiations
    // --------------------------------------------------------

    // Immediate generator
    imm_gen u_imm_gen (
    .instruction (instr_reg),
    .imm_out     (imm)
    );

    // Register file
    register_file u_register_file (
    .clk (clk),
    .read_addr_1    (rs1),
    .read_data_1    (rs1_data),
    .read_addr_2    (rs2),
    .read_data_2    (rs2_data),
    .write_enable   (reg_write),
    .write_addr     (rd),
    .write_data     (write_back_data)
    );

    // ALU operand B MUX
    // alu_src_b = 0 → use rs2_data
    // alu_src_b = 1 → use imm
    assign alu_operand_b = alu_src_b ? imm : rs2_data;

    // ALU
    alu u_alu (
    .operation  (alu_operation),
    .operand_a  (rs1_data),
    .operand_b  (alu_operand_b),
    .result     (alu_result),
    .zero       (alu_zero)
    );

    // Write-back MUX
    // mem_to_reg = 0 → write ALU result
    // mem_to_reg = 1 → write memory data
    assign write_back_data = mem_to_reg ? dmem_read_data : alu_result_reg;

    // --------------------------------------------------------
    // Data memory connections
    // --------------------------------------------------------

    assign dmem_addr       = alu_result_reg;
    assign dmem_write_data = rs2_data;
    assign dmem_write_en   = 0;  // will be driven by control unit later
    assign dmem_read_en    = 0;  // will be driven by control unit later

endmodule