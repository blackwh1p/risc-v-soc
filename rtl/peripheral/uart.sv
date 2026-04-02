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

    logic [9:0]  baud_counter;
    logic [7:0]  tx_shift_reg;
    logic [3:0]  bit_counter;
    logic [1:0]  tx_state;
    logic        tx_busy;

    // Baud rate counter limit
    localparam int BAUD_DIV = CLK_FREQ / BAUD_RATE;  // = 868 at 100MHz/115200

    // TX state definitions
    localparam logic [1:0] TX_IDLE  = 2'b00;
    localparam logic [1:0] TX_START = 2'b01;
    localparam logic [1:0] TX_DATA  = 2'b10;
    localparam logic [1:0] TX_STOP  = 2'b11;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx_state    <= TX_IDLE;
            uart_tx     <= 1'b1;    // idle HIGH
            baud_counter <= 0;
            bit_counter  <= 0;
            tx_busy      <= 0;
        end 
        else begin
            case (tx_state)
                TX_IDLE: begin
                    uart_tx  <= 1'b1;   // keep line HIGH
                    tx_busy  <= 0;

                    if (reg_write_en && reg_addr == 4'h0) begin
                        tx_shift_reg [7:0] <= reg_write_data [7:0];
                        tx_busy <= 1;
                        tx_state <= TX_START;
                        baud_counter <= 0;
                    end
                end

                TX_START: begin
                    uart_tx <= 1'b0;    // start bit — pull LOW
                    tx_busy <= 1;

                    baud_counter <= baud_counter + 1;
                    if (baud_counter == BAUD_DIV - 1) begin
                        baud_counter <= 0;
                        tx_state <= TX_DATA;
                        bit_counter <= 0;
                    end
                end

                TX_DATA: begin
                    uart_tx <= tx_shift_reg[0];  // send LSB
                    baud_counter <= baud_counter + 1;

                    if (baud_counter == BAUD_DIV - 1) begin
                        baud_counter <= 0;
                        tx_shift_reg <= tx_shift_reg >> 1;
                        bit_counter <= bit_counter + 1;

                        if (bit_counter == 7) begin
                            tx_state <= TX_STOP;
                            bit_counter <= 0;
                        end
                    end
                end

                TX_STOP: begin
                    uart_tx <= 1'b1;    // stop bit — HIGH
                    baud_counter <= baud_counter + 1;

                    if (baud_counter == BAUD_DIV - 1) begin
                        baud_counter <= 0;
                        tx_state <= TX_IDLE;
                    end
                end
            endcase
        end
    end

    // MMIO read logic
    always @(*) begin
        reg_read_data = 32'b0;
        if (reg_read_en) begin
            case (reg_addr)
                4'h0: reg_read_data = 32'b0;        // TX_DATA not readable
                4'h2: reg_read_data = {30'b0, 1'b0, ~tx_busy}; // STATUS: bit0=TX_ready
                default: reg_read_data = 32'b0;
            endcase
        end
    end

endmodule