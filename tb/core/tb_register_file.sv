// ============================================================
// Module  : tb_register_file
// Purpose : Testbench for register file module
//           Tests write/read, x0 protection, write_enable
// ============================================================

module tb_register_file;  // no ports — empty parentheses not needed

    // declare signals here
    logic clk;
    logic   [4:0]   read_addr_1;
    logic   [31:0]  read_data_1;

    logic   [4:0]   read_addr_2;
    logic   [31:0]  read_data_2;

    logic   write_enable;
    logic   [4:0]   write_addr;
    logic   [31:0]  write_data;

    // instantiate the device under test
    register_file dut (
        .clk (clk),
        .read_addr_1 (read_addr_1),
        .read_data_1 (read_data_1),
        .read_addr_2 (read_addr_2),
        .read_data_2 (read_data_2),

        .write_enable (write_enable),
        .write_addr (write_addr),
        .write_data (write_data)
    );

    // clock generator
    initial clk = 0;
    always #5 clk = ~clk;

    // test cases
    initial begin
        $dumpfile("sim_regfile.vcd");
        $dumpvars(0, tb_register_file);

        write_enable = 0;
        write_addr = 5'b0;
        write_data = 32'b0;
        read_addr_1 = 5'b0;
        read_addr_2 = 5'b0;

        @(posedge clk);
        #1;

        // --- Test 1: Write to x1 then read it back ---
        write_enable = 1;
        write_addr = 5'd1;
        write_data = 32'd8;

        @(posedge clk);
        #1;
        write_enable = 0;

        read_addr_1 = 5'd1;
        #1;
        if (read_data_1 == 32'd8)
            $display("PASS: Write/Read x1 = 8");
        else
            $display("FAIL: Write/Read x1 expected 8, got %0d", read_data_1);


        // --- Test 2: Write to x1 and x2, read both simultaneously ---
        write_enable = 1;
        write_addr = 5'd1;
        write_data = 32'd5;

        @(posedge clk);
        #1;

        write_addr = 5'd2;
        write_data = 32'd10;

        @(posedge clk);
        #1;
        write_enable = 0;

        read_addr_1 = 5'd1;
        read_addr_2 = 5'd2;
        #1;
        if (read_data_1 == 32'd5 && read_data_2 == 32'd10)
            $display("PASS: Write/Read x1 = 5 and Write/Read x2 = 10");
        else
            $display("FAIL: Write/Read x1 and x2 expected 5 and 10, got %0d and %0d", read_data_1, read_data_2);


        // --- Test 3: Write to x0, verify it stays zero ---
        write_enable = 1;
        write_addr = 5'd0;
        write_data = 32'd10;

        @(posedge clk);
        #1;
        write_enable = 0;

        read_addr_1 = 5'd0;
        #1;
        if (read_data_1 == 32'd0)
            $display("PASS: Write/Read x0 = 0");
        else
            $display("FAIL: Write/Read x0 expected 0, got %0d", read_data_1);


        // --- Test 4: Write with write_enable = 0, verify nothing changes ---
        write_enable = 0;
        write_addr = 5'd1;
        write_data = 32'd12;

        @(posedge clk);
        #1;
        write_enable = 0;

        read_addr_1 = 5'd1;
        #1;
        if (read_data_1 == 32'd5)
            $display("PASS: Write/Read x1 = 5");
        else
            $display("FAIL: Write/Read x1 expected 5, got %0d", read_data_1);
        
        $display("All tests completed.");
        $finish;
    end

endmodule