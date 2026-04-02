// ============================================================
// Module  : dmem
// Purpose : Data memory (read/write)
//           Implemented as Xilinx Block RAM
//           Supports byte, halfword, and word accesses
// Parameters:
//   MEM_DEPTH : number of 32-bit words (default 4096 = 16KB)
// ============================================================
module dmem #(
    parameter int MEM_DEPTH = 4096
)(
    input  logic        clk,

    // Read interface
    input  logic        read_en,        // HIGH = perform a read
    input  logic [31:0] addr,           // byte address
    output logic [31:0] read_data,      // data read from memory

    // Write interface
    input  logic        write_en,       // HIGH = perform a write
    input  logic [3:0]  byte_enable,    // which bytes to write (for byte/halfword ops)
    input  logic [31:0] write_data      // data to write
);

    // Internal logic will be added in Phase 3

endmodule