// ============================================================
// Module  : gpio
// Purpose : General Purpose I/O controller
//           Drives LEDs and reads buttons on Nexys A7
//           Connected to CPU via MMIO at 0x40002000
// ============================================================
module gpio (
    input  logic        clk,
    input  logic        rst_n,

    // MMIO register interface
    input  logic        reg_write_en,
    input  logic        reg_read_en,
    input  logic [3:0]  reg_addr,       // selects DIRECTION, OUTPUT, INPUT
    input  logic [31:0] reg_write_data,
    output logic [31:0] reg_read_data,

    // Physical GPIO pins (go to Nexys A7 LEDs and buttons)
    output logic [15:0] gpio_out,       // connected to 16 LEDs
    input  logic [15:0] gpio_in         // connected to buttons/switches
);

    // Internal logic will be added in Phase 3

endmodule