// ============================================================
// Module  : tb_sevenseg
// Purpose : Unit test for the 8-digit 7-segment display
//           controller. Uses CLK_FREQ=100_000 so SCAN_DIV=25
//           and all 8 anode transitions complete in 200 cycles.
// ============================================================

module tb_sevenseg;

    localparam int CLK_FREQ = 100_000;
    localparam int SCAN_DIV = CLK_FREQ / 4_000;  // 25

    logic        clk, rst_n;
    logic        reg_write_en, reg_read_en;
    logic [3:0]  reg_addr;
    logic [31:0] reg_write_data, reg_read_data;
    logic [7:0]  an;
    logic [6:0]  seg;
    logic        dp;
    logic [31:0] rdata;
    int          error_count;

    sevenseg #(.CLK_FREQ(CLK_FREQ)) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .reg_write_en  (reg_write_en),
        .reg_read_en   (reg_read_en),
        .reg_addr      (reg_addr),
        .reg_write_data(reg_write_data),
        .reg_read_data (reg_read_data),
        .an            (an),
        .seg           (seg),
        .dp            (dp)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic chk8(input logic [7:0] actual, input logic [7:0] expected, input string name);
        if (actual !== expected) begin
            error_count++;
            $display("FAIL: %s — expected 0x%02h, got 0x%02h", name, expected, actual);
        end else
            $display("PASS: %s = 0x%02h", name, actual);
    endtask

    task automatic chk7(input logic [6:0] actual, input logic [6:0] expected, input string name);
        if (actual !== expected) begin
            error_count++;
            $display("FAIL: %s — expected 0x%02h, got 0x%02h", name, expected, actual);
        end else
            $display("PASS: %s = 0x%02h", name, actual);
    endtask

    task automatic chkw(input logic [31:0] actual, input logic [31:0] expected, input string name);
        if (actual !== expected) begin
            error_count++;
            $display("FAIL: %s — expected 0x%08h, got 0x%08h", name, expected, actual);
        end else
            $display("PASS: %s = 0x%08h", name, actual);
    endtask

    task automatic mmio_write(input logic [3:0] addr, input logic [31:0] data);
        @(posedge clk); #1;
        reg_write_en   = 1'b1;
        reg_addr       = addr;
        reg_write_data = data;
        @(posedge clk); #1;
        reg_write_en   = 1'b0;
    endtask

    task automatic mmio_read(input logic [3:0] addr, output logic [31:0] data);
        @(posedge clk); #1;
        reg_read_en = 1'b1;
        reg_addr    = addr;
        #1;
        data = reg_read_data;
        @(posedge clk); #1;
        reg_read_en = 1'b0;
    endtask

    initial begin
        error_count    = 0;
        reg_write_en   = 1'b0;
        reg_read_en    = 1'b0;
        reg_addr       = 4'h0;
        reg_write_data = 32'h0;
        rst_n          = 1'b0;

        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); #1;

        // --- Test 1: Reset state — all anodes off, DP inactive ---
        chk8(an, 8'hFF, "AN at reset (all off)");
        if (dp !== 1'b1) begin
            error_count++;
            $display("FAIL: DP at reset — expected 1 (off), got %0b", dp);
        end else
            $display("PASS: DP=1 at reset");

        // --- Test 2: Write and read back DISPLAY register ---
        // display=0x76543210: digit_sel N shows nibble N
        mmio_write(4'h0, 32'h76543210);
        mmio_read(4'h0, rdata);
        chkw(rdata, 32'h76543210, "DISPLAY readback");

        // --- Test 3: Anodes still off while CONTROL=0 ---
        chk8(an, 8'hFF, "AN still off before enable");

        // --- Test 4: Enable display, read back CONTROL ---
        mmio_write(4'h4, 32'h1);
        mmio_read(4'h4, rdata);
        chkw(rdata, 32'h00000001, "CONTROL readback");

        // --- Test 5: Verify anode and segment for all 8 scan positions ---
        // display_reg = 0x76543210
        //   digit_sel=0 nibble=0h0  AN=FE  seg=~3F=40
        //   digit_sel=1 nibble=0h1  AN=FD  seg=~06=79
        //   digit_sel=2 nibble=0h2  AN=FB  seg=~5B=24
        //   digit_sel=3 nibble=0h3  AN=F7  seg=~4F=30
        //   digit_sel=4 nibble=0h4  AN=EF  seg=~66=19
        //   digit_sel=5 nibble=0h5  AN=DF  seg=~6D=12
        //   digit_sel=6 nibble=0h6  AN=BF  seg=~7D=02
        //   digit_sel=7 nibble=0h7  AN=7F  seg=~07=78
        wait (an == 8'hFE); #1;
        chk8(an,  8'hFE, "AN digit 0 anode");
        chk7(seg, 7'h40, "SEG digit 0 (nibble=0)");

        wait (an == 8'hFD); #1;
        chk8(an,  8'hFD, "AN digit 1 anode");
        chk7(seg, 7'h79, "SEG digit 1 (nibble=1)");

        wait (an == 8'hFB); #1;
        chk8(an,  8'hFB, "AN digit 2 anode");
        chk7(seg, 7'h24, "SEG digit 2 (nibble=2)");

        wait (an == 8'hF7); #1;
        chk8(an,  8'hF7, "AN digit 3 anode");
        chk7(seg, 7'h30, "SEG digit 3 (nibble=3)");

        wait (an == 8'hEF); #1;
        chk8(an,  8'hEF, "AN digit 4 anode");
        chk7(seg, 7'h19, "SEG digit 4 (nibble=4)");

        wait (an == 8'hDF); #1;
        chk8(an,  8'hDF, "AN digit 5 anode");
        chk7(seg, 7'h12, "SEG digit 5 (nibble=5)");

        wait (an == 8'hBF); #1;
        chk8(an,  8'hBF, "AN digit 6 anode");
        chk7(seg, 7'h02, "SEG digit 6 (nibble=6)");

        wait (an == 8'h7F); #1;
        chk8(an,  8'h7F, "AN digit 7 anode");
        chk7(seg, 7'h78, "SEG digit 7 (nibble=7)");

        // --- Test 6: Disable display — all anodes go dark immediately ---
        mmio_write(4'h4, 32'h0);
        @(posedge clk); #1;
        chk8(an, 8'hFF, "AN after disable");

        if (error_count == 0)
            $display("PASS: tb_sevenseg — all checks passed");
        else
            $display("FAIL: tb_sevenseg — %0d error(s)", error_count);
        $finish;
    end

endmodule
