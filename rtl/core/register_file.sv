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

    // 32 registers, each 32 bits wide
    // registers[0] is never written — x0 is hardwired to zero
    logic [31:0] registers [0:31];

    always_ff @(posedge clk) begin
        if (write_enable && write_addr != 5'b0)
            registers[write_addr] <= write_data;
    end

    assign read_data_1 = (read_addr_1 == 5'b0) ? 32'b0 : registers[read_addr_1];
    assign read_data_2 = (read_addr_2 == 5'b0) ? 32'b0 : registers[read_addr_2];

endmodule