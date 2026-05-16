// ============================================================
// Module  : tb_uart
// Purpose : Testbench for UART transmitter/receiver
//           Tests TX and RX status/data behavior
// ============================================================

module tb_uart;

    // --- Signals ---
    logic        clk;
    logic        rst_n;
    logic        reg_write_en;
    logic        reg_read_en;
    logic [3:0]  reg_addr;
    logic [31:0] reg_write_data;
    logic [31:0] reg_read_data;
    logic        uart_tx;
    logic        uart_rx;
    int          i;

    localparam int CLK_FREQ = 100_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int BAUD_DIV = CLK_FREQ / BAUD_RATE;

    // --- Instantiate uart ---
    uart #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk (clk),
        .rst_n (rst_n),

        .reg_write_en (reg_write_en),
        .reg_read_en (reg_read_en),
        .reg_addr (reg_addr),
        .reg_write_data (reg_write_data),
        .reg_read_data (reg_read_data),

        .uart_tx (uart_tx),
        .uart_rx (uart_rx)
    );

    // --- Clock generator ---
    initial clk = 0;
    always #5 clk = ~clk;

    task automatic send_rx_byte(input logic [7:0] value);
        begin
            uart_rx = 1'b0; // start bit
            repeat (BAUD_DIV) @(posedge clk);

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = value[i];
                repeat (BAUD_DIV) @(posedge clk);
            end

            uart_rx = 1'b1; // stop bit
            repeat (BAUD_DIV) @(posedge clk);
        end
    endtask

    // --- Test cases ---
    initial begin
        // Initialize signals
        rst_n         = 0;
        reg_write_en  = 0;
        reg_read_en   = 0;
        reg_addr      = 4'h0;
        reg_write_data = 32'b0;
        uart_rx       = 1'b1;  // idle HIGH

        @(posedge clk);
        #1;
        @(posedge clk);
        #1;

        rst_n = 1;
        #1;
        @(posedge clk);
        #1;


        // --- Test 1: Verify TX idle state ---
        if (uart_tx == 1'b1)
            $display("PASS: UART idle — TX line is HIGH");
        else
            $display("FAIL: UART idle — TX line expected HIGH, got %0b", uart_tx);


        // --- Test 2: Trigger TX with byte 'A' (0x41) ---
        reg_write_en = 1;
        reg_addr = 4'h0;
        reg_write_data = 32'h00000041;
        @(posedge clk);
        #1;

        reg_write_en = 0;
        @(posedge clk);
        #1;

        if (uart_tx == 1'b0)
            $display("PASS: TX start bit is LOW");
        else
            $display("FAIL: TX start bit expected LOW, got %0b", uart_tx);


        // --- Test 3: Check TX busy flag ---
        reg_read_en = 1;
        reg_addr = 4'h8;
        #1;

        if (reg_read_data[0] == 1'b0)
            $display("PASS: TX busy flag set correctly");
        else
            $display("FAIL: TX should be busy, got %0b", reg_read_data[0]);
        reg_read_en = 0;


        // --- Test 4: Wait for TX complete ---
        repeat(9000) @(posedge clk);
        #1;

        if (uart_tx == 1'b1)
            $display("PASS: TX complete — line returned HIGH");
        else
            $display("FAIL: TX not complete, line still LOW");

        reg_read_en = 1;
        reg_addr    = 4'h8;
        #1;

        if (reg_read_data[0] == 1'b1)
            $display("PASS: TX ready after transmission");
        else
            $display("FAIL: TX not ready after transmission");
        reg_read_en = 0;

        // --- Test 5: Drive one RX byte and check RX_VALID ---
        send_rx_byte(8'hA6);
        repeat (20) @(posedge clk);
        #1;

        reg_read_en = 1;
        reg_addr = 4'h8;
        #1;
        if (reg_read_data[1] == 1'b1)
            $display("PASS: RX valid flag set after receiving byte");
        else
            $display("FAIL: RX valid flag not set after receive");
        reg_read_en = 0;

        // --- Test 6: Read RX_DATA and verify byte content ---
        reg_read_en = 1;
        reg_addr = 4'h4;
        #1;
        if (reg_read_data[7:0] == 8'hA6)
            $display("PASS: RX_DATA returned 0xA6");
        else
            $display("FAIL: RX_DATA expected 0xA6, got 0x%02h", reg_read_data[7:0]);
        @(posedge clk);
        #1;
        reg_read_en = 0;

        // --- Test 7: RX valid should clear after RX_DATA read ---
        reg_read_en = 1;
        reg_addr = 4'h8;
        #1;
        if (reg_read_data[1] == 1'b0)
            $display("PASS: RX valid cleared after RX_DATA read");
        else
            $display("FAIL: RX valid did not clear after RX_DATA read");
        reg_read_en = 0;

        // --- Test 8: Overrun — send two bytes without reading between them ---
        send_rx_byte(8'hB1);    // first byte — not read, rx_valid stays 1
        send_rx_byte(8'hC2);    // second byte — arrives while rx_valid=1 → overrun
        repeat (20) @(posedge clk);
        #1;

        reg_read_en = 1;
        reg_addr = 4'h8;
        #1;
        if (reg_read_data[2] == 1'b1)
            $display("PASS: RX overrun flag set after second unread byte");
        else
            $display("FAIL: RX overrun flag not set (expected STATUS[2]=1, got %0b)", reg_read_data[2]);
        if (reg_read_data[1] == 1'b1)
            $display("PASS: RX valid still set during overrun");
        else
            $display("FAIL: RX valid should be set during overrun");
        reg_read_en = 0;

        // --- Test 9: Read RX_DATA — should be latest byte (0xC2); flags clear ---
        reg_read_en = 1;
        reg_addr = 4'h4;
        #1;
        if (reg_read_data[7:0] == 8'hC2)
            $display("PASS: RX_DATA is latest byte 0xC2 after overrun");
        else
            $display("FAIL: RX_DATA expected 0xC2, got 0x%02h", reg_read_data[7:0]);
        @(posedge clk);
        #1;
        reg_read_en = 0;

        reg_read_en = 1;
        reg_addr = 4'h8;
        #1;
        if (reg_read_data[2] == 1'b0 && reg_read_data[1] == 1'b0)
            $display("PASS: RX overrun and valid cleared after RX_DATA read");
        else
            $display("FAIL: STATUS[2:1] expected 2'b00 after read, got %0b%0b",
                     reg_read_data[2], reg_read_data[1]);
        reg_read_en = 0;

        $display("All UART tests completed.");
        $finish;
    end

endmodule
