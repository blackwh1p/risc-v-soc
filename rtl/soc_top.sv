// ============================================================
// Module  : soc_top
// Purpose : Top-level SoC module
//           Instantiates CPU, memories, and all peripherals
//           This is the root module for Vivado synthesis
// ============================================================
module soc_top (
    // Nexys A7 100MHz system clock
    input  logic        clk_100mhz,

    // Nexys A7 CPU reset button (active low)
    input  logic        rst_n,

    // UART pins (connected to USB-UART bridge on Nexys A7)
    output logic        uart_tx,
    input  logic        uart_rx,

    // LED outputs (16 LEDs on Nexys A7)
    output logic [15:0] leds,

    // Switch inputs (16 switches on Nexys A7)
    input  logic [15:0] switches,

    // Button inputs (5 buttons on Nexys A7)
    input  logic [4:0]  buttons
);

    // Internal logic will be added in Phase 3

endmodule