// ============================================================
// Module  : tb_uart
// Purpose : Testbench for UART transmitter
//           Tests TX start, busy flag, and completion
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

    // --- Instantiate uart ---
    uart dut (
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
        reg_addr = 4'h2;
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
        reg_addr    = 4'h2;
        #1;

        if (reg_read_data[0] == 1'b1)
            $display("PASS: TX ready after transmission");
        else
            $display("FAIL: TX not ready after transmission");
        reg_read_en = 0;

        $display("All UART tests completed.");
        $finish;
    end

endmodule