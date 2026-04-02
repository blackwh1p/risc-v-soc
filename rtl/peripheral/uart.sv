// ============================================================
// Module  : uart
// Purpose : UART transmitter and receiver
//           Baud rate configurable via parameter
//           Connected to CPU via MMIO at 0x40000000
// Parameters:
//   CLK_FREQ  : system clock frequency in Hz (default 100MHz)
//   BAUD_RATE : serial baud rate (default 115200)
// ============================================================
module uart #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input  logic        clk,
    input  logic        rst_n,

    // MMIO register interface (from CPU)
    input  logic        reg_write_en,
    input  logic        reg_read_en,
    input  logic [3:0]  reg_addr,       // selects TX_DATA, RX_DATA, or STATUS
    input  logic [31:0] reg_write_data,
    output logic [31:0] reg_read_data,

    // Physical UART pins (go to Nexys A7 USB-UART bridge)
    output logic        uart_tx,        // transmit pin
    input  logic        uart_rx         // receive pin
);

    // Internal logic will be added in Phase 3

endmodule