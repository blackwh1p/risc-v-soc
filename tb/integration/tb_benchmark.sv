// ============================================================
// Module  : tb_benchmark
// Purpose : Simulation testbench for benchmark.c.
//           Captures UART TX output and checks that the
//           "=== Done ===" sentinel arrives within the timeout.
// ============================================================

module tb_benchmark;

    localparam int UART_CLK_FREQ = 100_000_000;
    localparam int UART_BAUD     = 5_000_000;
    localparam int BAUD_DIV      = UART_CLK_FREQ / UART_BAUD;
    localparam int TIMEOUT_CYCS  = 500_000;

    logic        clk;
    logic        rst_n;
    logic        uart_tx;

    soc_top #(
        .IMEM_FILE      ("sw/tests/benchmark.mem"),
        .UART_CLK_FREQ  (UART_CLK_FREQ),
        .UART_BAUD_RATE (UART_BAUD)
    ) dut (
        .clk_100mhz (clk),
        .rst_n      (rst_n),
        .uart_tx    (uart_tx),
        .uart_rx    (1'b1),
        .leds       (),
        .switches   (16'h0),
        .buttons    (5'b0),
        .an         (),
        .seg        (),
        .dp         (),
        .spi_sck    (),
        .spi_cs_n   (),
        .spi_mosi   (),
        .spi_miso   (1'b0),
        .spi_wp_n   (),
        .spi_hold_n ()
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // UART byte receive task
    task automatic recv_uart_byte(output logic [7:0] val);
        integer i;
        val = 8'h00;
        wait (uart_tx == 1'b0);
        repeat (BAUD_DIV + (BAUD_DIV / 2)) @(posedge clk);
        for (i = 0; i < 8; i = i + 1) begin
            val[i] = uart_tx;
            repeat (BAUD_DIV) @(posedge clk);
        end
        repeat (BAUD_DIV) @(posedge clk);
    endtask

    // Rolling window to detect "Done" sentinel
    logic [7:0] window[0:3];
    logic [7:0] rx_byte;
    int         cycle_count;
    int         done_flag;

    initial begin
        rst_n      = 1'b0;
        cycle_count = 0;
        done_flag  = 0;
        window[0] = 8'h00; window[1] = 8'h00;
        window[2] = 8'h00; window[3] = 8'h00;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;

        fork
            // UART capture thread: print every byte, watch for "Done"
            begin
                forever begin
                    recv_uart_byte(rx_byte);
                    $write("%c", rx_byte);
                    window[0] <= window[1];
                    window[1] <= window[2];
                    window[2] <= window[3];
                    window[3] <= rx_byte;
                    @(posedge clk);
                    if (window[0] == "D" && window[1] == "o" &&
                        window[2] == "n" && window[3] == "e") begin
                        done_flag = 1;
                    end
                end
            end

            // Cycle counter + timeout
            begin
                while (cycle_count < TIMEOUT_CYCS) begin
                    @(posedge clk);
                    cycle_count = cycle_count + 1;
                    if (done_flag) begin
                        $display("\nPASS: benchmark completed after %0d cycles", cycle_count);
                        $finish;
                    end
                end
                $display("\nFAIL: benchmark timed out after %0d cycles", cycle_count);
                $fatal(1);
            end
        join
    end

endmodule
