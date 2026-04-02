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

    logic [15:0] direction_reg;     // 1=output, 0=input per bit
    logic [15:0] output_reg;        // holds values to drive on LEDs

    // 1 — Synchronous register write logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            output_reg <= 16'b0;
            direction_reg <= 16'b0;
        end
        else begin
            // CPU writes to registers
            if (reg_write_en) begin
                case (reg_addr)
                    4'h0: direction_reg <= reg_write_data[15:0];
                    4'h4: output_reg <= reg_write_data[15:0];
                endcase
            end
        end
    end

    // 2 — MMIO read logic
    always @(*) begin
        reg_read_data = 32'b0;
        if (reg_read_en) begin
            case (reg_addr)
                4'h0: reg_read_data = {16'b0, direction_reg};
                4'h4: reg_read_data = {16'b0, output_reg}; 
                4'h8: reg_read_data = {16'b0, gpio_in};
                default: reg_read_data = 32'b0;
            endcase
        end
    end

    // 3 — Pin connections
    assign gpio_out = output_reg;
    
endmodule