// ============================================================
// Module  : timer
// Purpose : 32-bit countdown/compare timer with interrupt
//           Connected to CPU via MMIO at 0x40001000
// ============================================================
module timer (
    input  logic        clk,
    input  logic        rst_n,

    // MMIO register interface
    input  logic        reg_write_en,
    input  logic        reg_read_en,
    input  logic [3:0]  reg_addr,       // selects COUNTER, COMPARE, CONTROL
    input  logic [31:0] reg_write_data,
    output logic [31:0] reg_read_data,

    // Interrupt output to CPU
    output logic        timer_interrupt  // goes HIGH when counter == compare
);

    // Internal logic will be added in Phase 3

endmodule