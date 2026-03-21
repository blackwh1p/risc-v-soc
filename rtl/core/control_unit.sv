// ============================================================
// Module  : control_unit
// Purpose : Multi-cycle FSM control unit for RV32IM
//           Decodes instructions and drives all control signals
//           States: FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK
// ============================================================
module control_unit (
    input  logic        clk,
    input  logic        rst_n,          // active-low reset

    // Current instruction from instruction register
    input  logic [31:0] instruction,

    // ALU result flags
    input  logic        alu_zero,       // HIGH when ALU result is zero

    // Control signals to datapath
    output logic [3:0]  alu_operation,  // tells ALU which operation to do
    output logic        alu_src_b,      // 0=register, 1=immediate
    output logic        reg_write,      // HIGH = write result to register file
    output logic        mem_read,       // HIGH = read from data memory
    output logic        mem_write,      // HIGH = write to data memory
    output logic        mem_to_reg,     // 0=ALU result, 1=memory data to register
    output logic        branch,         // HIGH = this is a branch instruction
    output logic        jump,           // HIGH = this is a jump instruction
    output logic [1:0]  pc_src          // selects next PC value
);

    // Internal logic will be added in Phase 2

endmodule