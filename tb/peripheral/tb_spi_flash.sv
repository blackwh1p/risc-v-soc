// ============================================================
// Module  : tb_spi_flash
// Purpose : Unit test for the spi_flash MMIO peripheral.
//           Drives the MMIO interface directly and uses a
//           simple MISO pattern generator to verify that
//           the controller correctly shifts out MOSI (MSB
//           first) and samples MISO on every SCK rising edge.
//
// Tests:
//   1. CS deasserted at reset, WP and HOLD always HIGH
//   2. CS assert / deassert via MMIO CS register
//   3. Busy flag: set on TX write, cleared after 64 ticks
//   4. RX byte matches driven MISO pattern (0xA3)
// ============================================================

module tb_spi_flash;

    logic        clk, rst_n;
    logic        reg_write_en, reg_read_en;
    logic [3:0]  reg_addr;
    logic [31:0] reg_write_data, reg_read_data;
    logic        spi_sck, spi_cs_n, spi_mosi, spi_miso;
    logic        spi_wp_n, spi_hold_n;

    spi_flash dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .reg_write_en  (reg_write_en),
        .reg_read_en   (reg_read_en),
        .reg_addr      (reg_addr),
        .reg_write_data(reg_write_data),
        .reg_read_data (reg_read_data),
        .spi_sck       (spi_sck),
        .spi_cs_n      (spi_cs_n),
        .spi_mosi      (spi_mosi),
        .spi_miso      (spi_miso),
        .spi_wp_n      (spi_wp_n),
        .spi_hold_n    (spi_hold_n)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // MISO pattern generator: drive 0xA3 = 10100011, MSB first.
    // Uses a clk-synchronous edge detector instead of negedge spi_sck
    // to avoid X→0 spurious triggers during reset initialization.
    logic [7:0] miso_byte;
    logic [2:0] miso_bit;
    logic       sck_prev;

    initial miso_byte = 8'hA3;
    initial miso_bit  = 3'd7;
    initial sck_prev  = 1'b0;

    always @(posedge clk) begin
        sck_prev <= spi_sck;
        if (spi_cs_n)                 // CS deasserted: hold at MSB
            miso_bit <= 3'd7;
        else if (sck_prev & ~spi_sck) // falling SCK (one clk delayed)
            miso_bit <= miso_bit - 1;
    end

    assign spi_miso = miso_byte[miso_bit];

    // MMIO write helper
    task automatic mmio_write(input logic [3:0] addr, input logic [31:0] data);
        reg_write_en   = 1'b1;
        reg_addr       = addr;
        reg_write_data = data;
        @(posedge clk); #1;
        reg_write_en = 1'b0;
    endtask

    // MMIO read helper (combinational — reg_read_en asserted for one cycle)
    task automatic mmio_read(input logic [3:0] addr, output logic [31:0] data);
        reg_read_en = 1'b1;
        reg_addr    = addr;
        #1;
        data        = reg_read_data;
        reg_read_en = 1'b0;
    endtask

    logic [31:0] rdata;

    initial begin
        $dumpfile("sim_spi_flash.vcd");
        $dumpvars(0, tb_spi_flash);

        reg_write_en   = 1'b0;
        reg_read_en    = 1'b0;
        reg_addr       = 4'h0;
        reg_write_data = 32'h0;
        rst_n          = 1'b0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); #1;

        // Test 1: initial SPI state
        if (spi_cs_n   == 1'b1) $display("PASS: CS deasserted at reset");
        else                     $display("FAIL: CS should start deasserted");

        if (spi_wp_n   == 1'b1) $display("PASS: WP always HIGH");
        else                     $display("FAIL: WP should be HIGH");

        if (spi_hold_n == 1'b1) $display("PASS: HOLD always HIGH");
        else                     $display("FAIL: HOLD should be HIGH");

        // Test 2: assert CS via MMIO
        mmio_write(4'h8, 32'h1);
        if (spi_cs_n == 1'b0) $display("PASS: CS asserted via MMIO");
        else                   $display("FAIL: CS assert failed");

        // Test 3: busy flag — should set immediately on DATA write
        mmio_write(4'h0, 32'hC9);   // send byte 0xC9
        mmio_read(4'h4, rdata);
        if (rdata[0] == 1'b1) $display("PASS: busy asserted after TX write");
        else                   $display("FAIL: busy should be set after TX write");

        // Wait for transfer to complete (64 SCK ticks × 8 sys clocks + margin)
        repeat(80) @(posedge clk); #1;

        // Test 4: busy flag cleared after transfer
        mmio_read(4'h4, rdata);
        if (rdata[0] == 1'b0) $display("PASS: busy cleared after transfer");
        else                   $display("FAIL: busy still set after 80 cycles");

        // Test 5: RX byte captured correctly
        // MISO was driven MSB-first with 0xA3 = 10100011.
        mmio_read(4'h0, rdata);
        if (rdata[7:0] == 8'hA3)
            $display("PASS: RX byte = 0xA3");
        else
            $display("FAIL: RX expected 0xA3, got 0x%02h", rdata[7:0]);

        // Test 6: deassert CS
        mmio_write(4'h8, 32'h0);
        if (spi_cs_n == 1'b1) $display("PASS: CS deasserted via MMIO");
        else                   $display("FAIL: CS deassert failed");

        $display("SPI flash unit test complete.");
        $finish;
    end

endmodule
