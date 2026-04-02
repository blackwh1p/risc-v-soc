// ============================================================
// Module  : tb_imem
// Purpose : Testbench for instruction memory module
//           Tests reading instructions loaded from .mem file
// ============================================================

module tb_imem;

    // --- Signals ---
    logic clk;

    logic [31:0] addr;
    logic [31:0] data;

    // --- Instantiate imem ---
    imem #(
    .MEM_DEPTH (4096),
    .MEM_FILE  ("sw/tests/test_imem.mem")
    ) dut (
        .clk  (clk),
        .addr (addr),
        .data (data)
    );

    // --- Clock generator ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Test cases ---
        initial begin
            addr = 32'b0;
            @(posedge clk);
            #1;

            // --- Test 1: Read instruction at address 0x00 ---
            addr = 32'h00000000;
            @(posedge clk);
            #1;

            if (data == 32'h00500093)
                $display("PASS: addr 0x00 = 0x00500093");
            else
                $display("FAIL: addr 0x00 expected 0x00500093, got %0h", data);

            // --- Test 2: Read instruction at address 0x04 ---
            addr = 32'h00000004;
            @(posedge clk);
            #1;

            if (data == 32'h00A00113)
                $display("PASS: addr 0x04 = 0x00A00113");
            else
                $display("FAIL: addr 0x04 expected 0x00A00113, got %0h", data);

            // --- Test 3: Read instruction at address 0x08 ---
            addr = 32'h00000008;
            @(posedge clk);
            #1;
            
            if (data == 32'h002081B3)
                $display("PASS: addr 0x08 = 0x002081B3");
            else
                $display("FAIL: addr 0x08 expected 0x002081B3, got %0h", data);
            
            $display("All imem tests completed.");
            $finish;
        end

endmodule