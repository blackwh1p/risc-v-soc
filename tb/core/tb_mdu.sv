// ============================================================
// Module  : tb_mdu
// Purpose : Unit testbench for the multi-cycle MDU.
//           Drives start, waits for done, checks result for
//           MUL/MULH/DIV/DIVU/REM/REMU including the RV32M
//           divide-by-zero and signed-overflow corner cases.
// ============================================================

import alu_ops::*;

module tb_mdu;

    logic        clk;
    logic        rst_n;
    logic        start;
    logic [4:0]  operation;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [31:0] result;
    logic        busy;
    logic        done;
    int          error_count;

    mdu dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .operation (operation),
        .operand_a (operand_a),
        .operand_b (operand_b),
        .result    (result),
        .busy      (busy),
        .done      (done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic run_op(
        input logic [4:0]  op,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [31:0] expected,
        input string       name
    );
        begin
            // Issue request
            @(posedge clk);
            operation <= op;
            operand_a <= a;
            operand_b <= b;
            start     <= 1'b1;
            @(posedge clk);
            start     <= 1'b0;

            // Wait for done (with a generous timeout)
            fork : wait_done
                begin
                    int w;
                    for (w = 0; w < 200; w = w + 1) begin
                        @(posedge clk);
                        if (done) disable wait_done;
                    end
                    error_count = error_count + 1;
                    $display("FAIL: %s — done never asserted within 200 cycles", name);
                end
            join

            #1;
            if (result !== expected) begin
                error_count = error_count + 1;
                $display("FAIL: %s expected 0x%08h, got 0x%08h", name, expected, result);
            end
            else begin
                $display("PASS: %s = 0x%08h", name, result);
            end
        end
    endtask

    initial begin
        rst_n       = 1'b0;
        start       = 1'b0;
        operation   = ALU_MUL;
        operand_a   = 32'b0;
        operand_b   = 32'b0;
        error_count = 0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // --- MUL ---
        run_op(ALU_MUL,  32'd6,        32'd7,        32'd42,        "MUL 6*7");
        run_op(ALU_MUL,  -32'sd5,      32'd4,        -32'sd20,      "MUL -5*4");

        // --- MULH (signed*signed upper 32 bits) ---
        run_op(ALU_MULH, 32'h80000000, 32'd2,        32'hFFFFFFFF,  "MULH INT_MIN*2");
        run_op(ALU_MULH, 32'h7FFFFFFF, 32'h7FFFFFFF, 32'h3FFFFFFF,  "MULH INT_MAX*INT_MAX");

        // --- MULHSU (signed × unsigned, upper 32 bits) ---
        // -1 × 0xFFFFFFFF: full product = 0xFFFFFFFF_00000001, upper = 0xFFFFFFFF
        run_op(ALU_MULHSU, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, "MULHSU -1*0xFFFFFFFF");
        // 2 × 3: full product = 6, upper = 0
        run_op(ALU_MULHSU, 32'd2,        32'd3,        32'd0,        "MULHSU 2*3");

        // --- MULHU (unsigned × unsigned, upper 32 bits) ---
        // 0x80000000 × 0x80000000 = 2^62 = 0x4000000000000000, upper = 0x40000000
        run_op(ALU_MULHU,  32'h80000000, 32'h80000000, 32'h40000000, "MULHU 2^31*2^31");
        // 0xFFFFFFFF × 0xFFFFFFFF = 0xFFFFFFFE00000001, upper = 0xFFFFFFFE
        run_op(ALU_MULHU,  32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFE, "MULHU 0xFFFF*0xFFFF");

        // --- DIV / DIVU / REM / REMU normal cases ---
        run_op(ALU_DIV,  32'd20,       32'd3,        32'd6,         "DIV 20/3");
        run_op(ALU_DIV,  -32'sd20,     32'd3,        -32'sd6,       "DIV -20/3");
        run_op(ALU_DIVU, 32'hFFFFFFFE, 32'd2,        32'h7FFFFFFF,  "DIVU large/2");
        run_op(ALU_REM,  32'd20,       32'd3,        32'd2,         "REM 20%3");
        run_op(ALU_REM,  -32'sd20,     32'd3,        -32'sd2,       "REM -20%3");
        run_op(ALU_REMU, 32'd17,       32'd5,        32'd2,         "REMU 17%5");

        // --- Divide-by-zero (RV32M spec) ---
        run_op(ALU_DIV,  32'd123,      32'd0,        32'hFFFFFFFF,  "DIV  by 0 -> -1");
        run_op(ALU_DIVU, 32'd123,      32'd0,        32'hFFFFFFFF,  "DIVU by 0 -> all-ones");
        run_op(ALU_REM,  32'd123,      32'd0,        32'd123,       "REM  by 0 -> dividend");
        run_op(ALU_REMU, 32'd123,      32'd0,        32'd123,       "REMU by 0 -> dividend");

        // --- Signed overflow (RV32M spec) ---
        run_op(ALU_DIV,  32'h80000000, 32'hFFFFFFFF, 32'h80000000,  "DIV INT_MIN/-1 -> INT_MIN");
        run_op(ALU_REM,  32'h80000000, 32'hFFFFFFFF, 32'd0,         "REM INT_MIN/-1 -> 0");

        if (error_count != 0) begin
            $display("MDU testbench failed with %0d error(s).", error_count);
            $fatal(1);
        end

        $display("All MDU tests completed.");
        $finish;
    end

endmodule
