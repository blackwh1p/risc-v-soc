// ============================================================
// Module  : tb_alu
// Purpose : Testbench for ALU module
//           Tests all 10 operations with directed test cases
// ============================================================

import alu_ops::*;

module tb_alu;

    // Step 1 — Declare signals that connect to the ALU ports
    // (these are just wires in the testbench)
    logic [3:0]  operation;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [31:0] result;
    logic        zero;

    // Step 2 — Instantiate the ALU
    alu alu_dut (
        .operation (operation),
        .operand_a (operand_a),
        .operand_b (operand_b),
        .result (result),
        .zero (zero)
    );

    // Step 3 — Write the test cases
    initial begin
        // Test ADD: 5 + 3 = 8
        operation = ALU_ADD;
        operand_a = 32'd5;
        operand_b = 32'd3;
        #10; // wait 10 time units for result to settle
        if (result == 32'd8)
            $display("PASS: ADD 5 + 3 = 8");
        else
            $display("FAIL: ADD expected 8, got %0d", result);

        // Test SUB
        operation = ALU_SUB;
        operand_a = 32'd8;
        operand_b = 32'd3;
        #10;
        if (result == 32'd5)
            $display("PASS: SUB 8 - 3 = 5");
        else
            $display("FAIL: SUB expected 5, got %0d", result);

        // Test AND
        operation = ALU_AND;
        operand_a = 32'd5;
        operand_b = 32'd3;
        #10;
        if (result == 32'd1)
            $display("PASS: AND 5 & 3 = 1");
        else
            $display("FAIL: AND expected 1, got %0d", result);

        // Test OR
        operation = ALU_OR;
        operand_a = 32'd5;
        operand_b = 32'd3;
        #10;
        if (result == 32'd7)
            $display("PASS: OR 5 | 3 = 7");
        else
            $display("FAIL: OR expected 7, got %0d", result);

        // Test XOR
        operation = ALU_XOR;
        operand_a = 32'd5;
        operand_b = 32'd3;
        #10;
        if (result == 32'd6)
            $display("PASS: XOR 5 ^ 3 = 6");
        else
            $display("FAIL: XOR expected 6, got %0d", result);

        // Test SLL
        operation = ALU_SLL;
        operand_a = 32'd5;
        operand_b = 32'd2;
        #10;
        if (result == 32'd20)
            $display("PASS: SLL 5 << 2 = 20");
        else
            $display("FAIL: SLL expected 20, got %0d", result);

        // Test SRL
        operation = ALU_SRL;
        operand_a = 32'd5;
        operand_b = 32'd2;
        #10;
        if (result == 32'd1)
            $display("PASS: SRL 5 >> 2 = 1");
        else
            $display("FAIL: SRL expected 1, got %0d", result);

        // Test SRA
        operation = ALU_SRA;
        operand_a = -32'd8;
        operand_b = 32'd2;
        #10;
        if (result == -32'd2)
            $display("PASS: SRA -8 >>> 2 = -2");
        else
            $display("FAIL: SRA expected -2, got %0d", result);

        // Test SLT: -1 < 1 should give 1
        operation = ALU_SLT;
        operand_a = -32'd1;
        operand_b = 32'd1;
        #10;
        if (result == 32'd1)
            $display("PASS: SLT -1 < 1 = 1");
        else
            $display("FAIL: SLT expected 1, got %0d", result);

        // Test SLTU: large unsigned < small → should give 0
        operation = ALU_SLTU;
        operand_a = 32'd12;
        operand_b = 32'd3;
        #10;
        if (result == 32'd0)
            $display("PASS: SLTU 12 < 3 = 0");
        else
            $display("FAIL: SLTU expected 0, got %0d", result);

        // Test zero flag: 5 - 5 = 0, zero should be 1
        operation = ALU_SUB;
        operand_a = 32'd5;
        operand_b = 32'd5;
        #10;
        if (zero == 1'b1)
            $display("PASS: ZERO = 1, when 5 - 5 = 0");
        else
            $display("FAIL: ZERO expected 1, got %0b", zero);

        $display("All tests completed.");
        $finish;
    end

endmodule