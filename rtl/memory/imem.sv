// ============================================================
// Module  : imem
// Purpose : Instruction memory (read-only)
//           Implemented as Xilinx Block RAM in ROM mode
//           Initialized from a .mem file at synthesis time
// Parameters:
//   MEM_DEPTH : number of 32-bit words (default 4096 = 16KB)
//   MEM_FILE  : path to memory initialization file
// ============================================================
module imem #(
    parameter int MEM_DEPTH = 4096,
    parameter     MEM_FILE  = "imem.mem"
)(
    input  logic        clk,

    // Read interface
    input  logic [31:0] addr,           // byte address from CPU
    output logic [31:0] data            // 32-bit instruction output
);

    // Internal logic will be added in Phase 3

endmodule