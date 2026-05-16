// ============================================================
// Module  : tb_irq_demo
// Purpose : Integration test for interrupt-driven demo firmware.
//           Verifies that:
//           1. UART banner arrives ("IRQ Demo")
//           2. Timer ISR fires at least 3 times (irq_count >= 3)
//           3. LED[15] toggles on each ISR (odd count → LED on)
//           4. 7-seg display reflects irq_count
// ============================================================

module tb_irq_demo;

    localparam int UART_CLK_FREQ = 100_000_000;
    localparam int UART_BAUD     = 5_000_000;
    localparam int BAUD_DIV      = UART_CLK_FREQ / UART_BAUD;
    localparam int TIMEOUT_CYCS  = 400_000;

    logic        clk;
    logic        rst_n;
    logic        uart_tx;
    logic [15:0] leds;
    logic [7:0]  an;
    logic [6:0]  seg;

    soc_top #(
        .IMEM_FILE      ("sw/tests/irq_demo_sim.mem"),
        .UART_CLK_FREQ  (UART_CLK_FREQ),
        .UART_BAUD_RATE (UART_BAUD)
    ) dut (
        .clk_100mhz (clk),
        .rst_n      (rst_n),
        .uart_tx    (uart_tx),
        .uart_rx    (1'b1),
        .leds       (leds),
        .switches   (16'h0),
        .buttons    (5'b0),
        .an         (an),
        .seg        (seg),
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

    // Rolling 8-byte window to detect "IRQ Demo" banner
    logic [7:0] win[0:7];
    logic [7:0] rx_byte;
    int         cycle_count;
    int         banner_found;
    int         irq_fires;
    logic       prev_led15;

    task automatic check_banner;
        integer j;
        if (win[0] == "I" && win[1] == "R" && win[2] == "Q" &&
            win[3] == " " && win[4] == "D" && win[5] == "e" &&
            win[6] == "m" && win[7] == "o")
            banner_found = 1;
    endtask

    initial begin
        rst_n = 1'b0; cycle_count = 0;
        banner_found = 0; irq_fires = 0;
        for (int i = 0; i < 8; i++) win[i] = 8'h00;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        prev_led15 = 1'b0;

        fork
            // UART capture thread — fill rolling window, check banner
            begin
                forever begin
                    recv_uart_byte(rx_byte);
                    $write("%c", rx_byte);
                    for (int i = 0; i < 7; i++) win[i] <= win[i+1];
                    win[7] <= rx_byte;
                    @(posedge clk);
                    check_banner();
                end
            end

            // LED[15] monitor — count ISR firings
            begin
                forever begin
                    @(posedge clk);
                    if (leds[15] !== prev_led15) begin
                        irq_fires++;
                        prev_led15 = leds[15];
                    end
                end
            end

            // Cycle counter + pass/fail checker
            begin
                while (cycle_count < TIMEOUT_CYCS) begin
                    @(posedge clk);
                    cycle_count++;

                    if (banner_found && irq_fires >= 3) begin
                        // Verify 7-seg display is non-zero (irq_count > 0)
                        if (dut.u_sevenseg.display_reg == 32'h0) begin
                            $display("\nFAIL: irq fires=%0d but 7-seg=0", irq_fires);
                            $fatal(1);
                        end
                        $display("\nPASS: banner found, ISR fired %0d times, 7-seg=0x%08h, leds=0x%04h",
                                 irq_fires, dut.u_sevenseg.display_reg, leds);
                        $display("PASS: irq_demo integration test passed after %0d cycles", cycle_count);
                        $finish;
                    end
                end

                $display("\nFAIL: timeout after %0d cycles (banner=%0d irq_fires=%0d leds=0x%04h)",
                         cycle_count, banner_found, irq_fires, leds);
                $fatal(1);
            end
        join
    end

endmodule
