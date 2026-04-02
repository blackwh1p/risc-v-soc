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

    logic [31:0]    counter_reg;    // current counter value
    logic [31:0]    compare_reg;    // compare value
    logic [1:0]     control_reg;    // bit0=enable, bit1=int_enable

    // 1 — Synchronous register write logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            counter_reg <= 32'b0;
            compare_reg <= 32'b0;
            control_reg <= 2'b0;
        end
        else begin
            // CPU writes to registers
            if (reg_write_en) begin
                case (reg_addr)
                    4'h0: counter_reg <= reg_write_data;
                    4'h4: compare_reg <= reg_write_data;
                    4'h8: control_reg <= reg_write_data[1:0];
                endcase
            end
            else if (control_reg[0]) begin
                // Timer enabled — increment counter
                if (counter_reg == compare_reg)
                    counter_reg <= 32'b0;
                else
                    counter_reg <= counter_reg + 1;
            end
        end
    end

    // 2 — Interrupt output logic
    assign timer_interrupt = control_reg[1] && (counter_reg == compare_reg);

    // 3 — MMIO read logic
    always @(*) begin
        reg_read_data = 32'b0;
        if (reg_read_en) begin
            case (reg_addr)
                4'h0: reg_read_data = counter_reg;
                4'h4: reg_read_data = compare_reg;
                4'h8: reg_read_data = {30'b0, control_reg};
                default: reg_read_data = 32'b0;
            endcase
        end
    end

endmodule