// ============================================================
// Module  : register_file
// Purpose : 32x32-bit register file for RV32IM
//           2 asynchronous read ports, 1 synchronous write port
//           x0 is hardwired to zero
// ============================================================
module register_file (
    input  logic        clk,

    // Read port 1 — provides the value of register rs1
    input  logic [4:0]  read_addr_1,    // register index (0-31)
    output logic [31:0] read_data_1,    // value of that register

    // Read port 2 — provides the value of register rs2
    input  logic [4:0]  read_addr_2,    // register index (0-31)
    output logic [31:0] read_data_2,    // value of that register

    // Write port — writes a value into a register on clock edge
    input  logic        write_enable,   // must be HIGH to write
    input  logic [4:0]  write_addr,     // which register to write (0-31)
    input  logic [31:0] write_data      // value to write
);

    // Internal logic will be added in Phase 2

endmodule