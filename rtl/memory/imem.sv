// ============================================================
// Module  : imem
// Purpose : Instruction memory — read-only at synthesis when
//           loaded from a .mem file, but also exposes a write
//           port used by the UART bootloader at run-time.
//           The write port is mapped to the SoC MMIO window
//           0x50000000–0x50003FFF in soc_top so the CPU can
//           program IMEM without a bitstream rebuild.
// Parameters:
//   MEM_DEPTH : number of 32-bit words (default 8192 = 32KB)
//   MEM_FILE  : path to memory initialization file
// ============================================================
module imem #(
    parameter int MEM_DEPTH = 8192,
    parameter     MEM_FILE  = "soc_diag.mem"
)(
    input  logic        clk,

    // Instruction fetch read interface
    input  logic [31:0] addr,           // byte address from CPU PC
    output logic [31:0] data,           // 32-bit instruction output

    // Data load read interface (for la/lw from IMEM, .data copy)
    input  logic [31:0] data_addr,      // byte address from CPU dmem port
    output logic [31:0] data_read_data, // 32-bit data for load path

    // Bootloader write port (driven by IMEM write window in soc_top)
    input  logic        write_en,
    input  logic [12:0] write_addr,     // word address (13-bit = 8192 words)
    input  logic [31:0] write_data
);

    logic [31:0] mem [0:MEM_DEPTH-1];
    localparam int ADDR_WIDTH = $clog2(MEM_DEPTH);

    initial if (MEM_FILE != "") $readmemh(MEM_FILE, mem);

    always @(posedge clk) begin
        if (write_en)
            mem[write_addr] <= write_data;
        data           <= mem[addr[ADDR_WIDTH+1:2]];
        data_read_data <= mem[data_addr[ADDR_WIDTH+1:2]];
    end

endmodule
