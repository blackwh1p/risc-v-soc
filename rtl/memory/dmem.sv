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
    input  logic    clk,

    // Read interface
    input  logic        read_en,        // HIGH = perform a read
    input  logic [31:0] addr,           // byte address
    output logic [31:0] read_data,      // data read from memory

    // Write interface
    input  logic        write_en,       // HIGH = perform a write
    input  logic [3:0]  byte_enable,    // which bytes to write (for byte/halfword ops)
    input  logic [31:0] write_data      // data to write
);

    logic [31:0] mem [0:MEM_DEPTH-1];

    always @(posedge clk) begin
        if (write_en) begin
            if (byte_enable[0]) mem[addr[31:2]] [7:0]   <= write_data[7:0];
            if (byte_enable[1]) mem[addr[31:2]] [15:8]  <= write_data[15:8];
            if (byte_enable[2]) mem[addr[31:2]] [23:16] <= write_data[23:16];
            if (byte_enable[3]) mem[addr[31:2]] [31:24] <= write_data[31:24];
        end
    end

    always @(posedge clk) begin
        if(read_en)
            read_data <= mem[addr[31:2]];
    end

endmodule