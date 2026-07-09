// ============================================================
// Module  : tb_timer
// Purpose : Testbench for timer module
//           Tests counter increment, compare match,
//           interrupt output, and timer disable
// ============================================================

module tb_timer;

    // --- Signals ---
    logic        clk;
    logic        rst_n;
    logic        reg_write_en;
    logic        reg_read_en;
    logic [3:0]  reg_addr;
    logic [31:0] reg_write_data;
    logic [31:0] reg_read_data;
    logic        timer_interrupt;
    logic [31:0] saved_value;
    logic        interrupt_seen;

    // --- Instantiate timer ---
    timer dut (
        .clk (clk),
        .rst_n (rst_n),

        .reg_write_en (reg_write_en),
        .reg_read_en (reg_read_en),
        .reg_addr (reg_addr),
        .reg_write_data (reg_write_data),
        .reg_read_data (reg_read_data),

        .timer_interrupt (timer_interrupt)
    );

    // --- Clock generator ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Test cases ---
    initial begin
        $dumpfile("sim_timer.vcd");
        $dumpvars(0, tb_timer);


        // --- Initialize signals ---
        rst_n         = 0;
        reg_write_en  = 0;
        reg_read_en   = 0;
        reg_addr      = 4'h0;
        reg_write_data = 32'b0;

        // --- Apply reset ---
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;

        rst_n = 1;
        #1;
        @(posedge clk);
        #1;


        // --- Test 1: Counter increments when enabled ---
        
        // COMPARE register (addr 0x4)
        reg_write_en = 1;
        reg_addr = 4'h4;
        reg_write_data = 32'd1000;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        // CONTROL register (addr 0x8)
        reg_write_en = 1;
        reg_addr = 4'h8;
        reg_write_data = 32'd1;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        repeat(5) @(posedge clk);
        #1;
        
        reg_read_en = 1;
        reg_addr = 4'h0;
        #1;
        if (reg_read_data > 32'd0)
            $display("PASS: Counter incremented after enable, got %0d", reg_read_data);
        else
            $display("FAIL: Counter did not increment, got %0d", reg_read_data);
        reg_read_en = 0;


        // --- Test 2: Counter resets at compare match ---

        // COMPARE register (addr 0x4)
        reg_write_en = 1;
        reg_addr = 4'h4;
        reg_write_data = 32'd5;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        // CONTROL register (addr 0x8)
        reg_write_en = 1;
        reg_addr = 4'h8;
        reg_write_data = 32'd1;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        repeat(10) @(posedge clk);
        #1;

        reg_read_en = 1;
        reg_addr = 4'h0;
        #1;
        if (reg_read_data < 32'd5)
            $display("PASS: Counter reset after compare match, got %0d", reg_read_data);
        else
            $display("FAIL: Counter did not reset, got %0d", reg_read_data);
        reg_read_en = 0;


        // --- Test 3: Interrupt fires at compare match ---

        // Reset Flag
        interrupt_seen = 0;

        // COMPARE register (addr 0x4)
        reg_write_en = 1;
        reg_addr = 4'h4;
        reg_write_data = 32'd5;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        // CONTROL register (addr 0x8)
        reg_write_en = 1;
        reg_addr = 4'h8;
        reg_write_data = 32'd3;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        repeat(10) begin
            @(posedge clk);
            #1;
            if (timer_interrupt == 1)
                interrupt_seen = 1;
        end

        if (interrupt_seen == 1)
            $display("PASS: Interrupt fired at compare match");
        else
            $display("FAIL: Interrupt did not fire, timer_interrupt=%0b", timer_interrupt);



        // --- Test 4: Timer disabled — counter does not increment ---

        reg_read_en = 1;
        reg_addr = 4'h0;
        #1;
        saved_value = reg_read_data;
        reg_read_en = 0;

        reg_write_en   = 1;
        reg_addr       = 4'h8;
        reg_write_data = 32'd0;  // disable timer
        @(posedge clk);
        #1;
        reg_write_en   = 0;

        repeat(3) @(posedge clk);
        #1;

        reg_read_en = 1;
        reg_addr = 4'h0;
        #1;

        if (reg_read_data == saved_value)
            $display("PASS: Counter unchanged when timer disabled");
        else
            $display("FAIL: Counter changed when disabled, expected %0d got %0d", saved_value, reg_read_data);

        $display("All timer tests completed.");
        $finish;
    end

endmodule