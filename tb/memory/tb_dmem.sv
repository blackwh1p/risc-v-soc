// ============================================================
// Module  : tb_dmem
// Purpose : Testbench for data memory module
//           Tests word write/read, byte write, read enable
// ============================================================

module tb_dmem;

// --- Signals ---
    logic clk;

    logic read_en;
    logic [31:0] addr;
    logic [31:0] read_data;

    logic write_en;
    logic [3:0] byte_enable;
    logic [31:0] write_data;

    // --- Instantiate dmem ---
    dmem #(
        .MEM_DEPTH (4096)
        ) dut (
            .clk  (clk),
            .read_en (read_en),
            .addr (addr),
            .read_data (read_data),
            .write_en (write_en),
            .byte_enable (byte_enable),
            .write_data (write_data)
        );

    // --- Clock generator ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Test cases ---
        initial begin
            $dumpfile("sim_dmem.vcd");
            $dumpvars(0, tb_dmem);

            addr = 32'b0;
            read_en = 0;
            write_en = 0;
            byte_enable = 4'b0000;
            write_data = 32'b0;
            @(posedge clk);
            #1;

            // --- Test 1: Word write and read back ---
            write_en = 1;
            byte_enable = 4'b1111;
            addr = 32'h00000000;
            write_data = 32'hDEADBEEF;
            @(posedge clk);
            #1;

            write_en = 0;
            read_en = 1;
            @(posedge clk);
            #1;

            if (read_data == 32'hDEADBEEF)
                $display("PASS: addr 0x00 = 0xDEADBEEF");
            else
                $display("FAIL: addr 0x00 expected 0xDEADBEEF, got %0h", read_data);

            // --- Test 2: Byte write — only byte 0 changes ---
            write_en = 1;
            byte_enable = 4'b0001;
            addr = 32'h00000004;
            write_data = 32'hFFFFFFFF;
            @(posedge clk);
            #1;

            write_en = 0;
            read_en = 1;
            @(posedge clk);
            #1;

            if ((read_data & 32'h000000FF) == 32'h000000FF)
                $display("PASS: Byte write addr 0x04, byte 0 = 0xFF");
            else
                $display("FAIL: Byte write expected byte 0 = 0xFF, got %0h", read_data);

            // --- Test 3: Read enable = 0, verify no update ---
            read_en = 1;
            addr = 32'h00000000;    
            @(posedge clk);
            #1;

            read_en = 0;
            addr = 32'h00000004;
            @(posedge clk);
            #1;

            if (read_data == 32'hDEADBEEF)
                $display("PASS: read_en=0 did not update read_data");
            else
                $display("FAIL: read_data updated when read_en=0, got %0h", read_data);

            $display("All dmem tests completed.");
            $finish;
        end

endmodule