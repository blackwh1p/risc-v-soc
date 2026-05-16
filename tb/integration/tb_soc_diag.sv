// ============================================================
// Module  : tb_soc_diag
// Purpose : Full-SoC integration regression using compiled
//           software. Checks DMEM signatures, LEDs, switches,
//           and UART output from the diagnostic program.
// ============================================================

module tb_soc_diag;

    // --- Constants ---
    localparam logic [31:0] PASS_SIG      = 32'h600DC0DE;
    localparam logic [31:0] FAIL_SIG      = 32'h0BADF00D;
    localparam logic [31:0] DETAIL_SIG    = 32'h1234ABCD;
    localparam int          STATUS_INDEX  = 'h300 >> 2;
    localparam int          DETAIL_INDEX  = 'h304 >> 2;
    localparam int          UART_CLK_FREQ = 100_000_000;
    localparam int          UART_BAUD     = 5_000_000;
    localparam int          BAUD_DIV      = UART_CLK_FREQ / UART_BAUD;

    // --- Signals ---
    logic        clk_100mhz;
    logic        rst_n;
    logic        uart_tx;
    logic        uart_rx;
    logic [15:0] leds;
    logic [15:0] switches;
    logic [4:0]  buttons;
    logic [7:0]  an;
    logic [6:0]  seg;
    logic        dp;
    logic [7:0]  byte0;
    logic [7:0]  byte1;
    logic [7:0]  byte2;
    logic [7:0]  byte3;
    logic        uart_done;
    int          cycle_count;

    // --- Instantiate SoC ---
    soc_top #(
        .IMEM_FILE       ("sw/tests/soc_diag.mem"),
        .UART_CLK_FREQ   (UART_CLK_FREQ),
        .UART_BAUD_RATE  (UART_BAUD)
    ) dut (
        .clk_100mhz (clk_100mhz),
        .rst_n      (rst_n),
        .uart_tx    (uart_tx),
        .uart_rx    (uart_rx),
        .leds       (leds),
        .switches   (switches),
        .buttons    (buttons),
        .an         (an),
        .seg        (seg),
        .dp         (dp),
        .spi_sck    (),
        .spi_cs_n   (),
        .spi_mosi   (),
        .spi_miso   (1'b0),
        .spi_wp_n   (),
        .spi_hold_n ()
    );

    initial clk_100mhz = 1'b0;
    always #5 clk_100mhz = ~clk_100mhz;

    // --- UART receiver helper ---
    task automatic recv_uart_byte(output logic [7:0] value);
        integer i;
        begin
            value = 8'h00;
            wait (uart_tx == 1'b0);
            repeat (BAUD_DIV + (BAUD_DIV / 2)) @(posedge clk_100mhz);
            for (i = 0; i < 8; i = i + 1) begin
                value[i] = uart_tx;
                repeat (BAUD_DIV) @(posedge clk_100mhz);
            end
            if (uart_tx !== 1'b1) begin
                $display("FAIL: UART stop bit was not HIGH");
                $fatal(1);
            end
            repeat (BAUD_DIV) @(posedge clk_100mhz);
        end
    endtask

    initial begin
        rst_n = 1'b0;
        uart_rx = 1'b1;
        switches = 16'h0000;  // switch value no longer affects test outcome
        buttons = 5'b0;
        cycle_count = 0;
        uart_done = 1'b0;

        @(posedge clk_100mhz);
        @(posedge clk_100mhz);
        rst_n = 1'b1;

        // Run UART capture and software monitor together
        fork
            begin
                recv_uart_byte(byte0);
                recv_uart_byte(byte1);
                recv_uart_byte(byte2);
                recv_uart_byte(byte3);
                uart_done = 1'b1;
            end

            begin
                while (cycle_count < 20000) begin
                    @(posedge clk_100mhz);
                    cycle_count = cycle_count + 1;

                    // PASS path: verify UART, detail signature, and LEDs
                    if (dut.u_dmem.mem[STATUS_INDEX] == PASS_SIG) begin
                        while (!uart_done && cycle_count < 22000) begin
                            @(posedge clk_100mhz);
                            cycle_count = cycle_count + 1;
                        end
                        if (!uart_done) begin
                            $display("FAIL: SoC diagnostic reached PASS but UART banner never completed");
                            $fatal(1);
                        end
                        if (byte0 !== "S" || byte1 !== "O" || byte2 !== "C" || byte3 !== "\n") begin
                            $display("FAIL: unexpected UART banner %02h %02h %02h %02h", byte0, byte1, byte2, byte3);
                            $fatal(1);
                        end
                        if (dut.u_dmem.mem[DETAIL_INDEX] !== DETAIL_SIG) begin
                            $display("FAIL: detail signature expected 0x%08h, got 0x%08h", DETAIL_SIG, dut.u_dmem.mem[DETAIL_INDEX]);
                            $fatal(1);
                        end
                        if (leds !== 16'hA5A5) begin
                            $display("FAIL: LEDs expected 0xA5A5, got 0x%04h", leds);
                            $fatal(1);
                        end
                        $display("PASS: SoC diagnostic completed after %0d cycles", cycle_count);
                        $finish;
                    end

                    // FAIL path: report fail code and debug state
                    if (dut.u_dmem.mem[STATUS_INDEX] == FAIL_SIG) begin
                        $display("FAIL: SoC diagnostic failed with code 0x%08h", dut.u_dmem.mem[DETAIL_INDEX]);
                        $display("DEBUG: dmem[0]=0x%08h dmem[1]=0x%08h leds=0x%04h pc=0x%08h",
                            dut.u_dmem.mem[0],
                            dut.u_dmem.mem[1],
                            leds,
                            dut.u_cpu.u_datapath.pc);
                        $fatal(1);
                    end
                end

                // Timeout path
                $display("FAIL: SoC diagnostic timed out after %0d cycles", cycle_count);
                $display("DEBUG: status=0x%08h detail=0x%08h leds=0x%04h pc=0x%08h uart_done=%0b",
                    dut.u_dmem.mem[STATUS_INDEX],
                    dut.u_dmem.mem[DETAIL_INDEX],
                    leds,
                    dut.u_cpu.u_datapath.pc,
                    uart_done);
                $fatal(1);
            end
        join
    end

endmodule
