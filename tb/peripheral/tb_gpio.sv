// ============================================================
// Module  : tb_gpio
// Purpose : Testbench for GPIO module
//           Tests output write, input read, direction register,
//           and reset behavior
// ============================================================

module tb_gpio;

    // --- Signals ---
    logic        clk;
    logic        rst_n;
    logic        reg_write_en;
    logic        reg_read_en;
    logic [3:0]  reg_addr;
    logic [31:0] reg_write_data;
    logic [31:0] reg_read_data;
    logic [15:0] gpio_out;
    logic [15:0] gpio_in;
    logic [4:0]  gpio_buttons;

    // --- Instantiate gpio ---
    gpio dut (
        .clk (clk),
        .rst_n (rst_n),

        .reg_write_en (reg_write_en),
        .reg_read_en (reg_read_en),
        .reg_addr (reg_addr),
        .reg_write_data (reg_write_data),
        .reg_read_data (reg_read_data),

        .gpio_out (gpio_out),
        .gpio_in (gpio_in),
        .gpio_buttons (gpio_buttons)
    );

    // --- Clock generator ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Test cases ---
    initial begin

        // --- Initialize signals ---
        rst_n         = 0;
        reg_write_en  = 0;
        reg_read_en   = 0;
        reg_addr      = 4'h0;
        reg_write_data = 32'b0;
        gpio_in       = 16'b0;
        gpio_buttons  = 5'b0;

        // --- Apply reset ---
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;

        rst_n = 1;
        #1;
        @(posedge clk);
        #1;

        // --- Test 1: Set direction=all-outputs, write OUTPUT, verify gpio_out ---
        reg_write_en = 1;
        reg_addr = 4'h0;
        reg_write_data = 32'h0000FFFF;  // all outputs
        @(posedge clk); #1;

        reg_addr = 4'h4;
        reg_write_data = 32'h0000FF00;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        if(gpio_out == 16'hFF00)
            $display("PASS: gpio_out = 0xFF00");
        else
            $display("FAIL: gpio_out expected 0xFF00, got %0h", gpio_out);


        // --- Test 2: Read from INPUT register ---
        // Set external inputs then wait 2 posedges for 2-FF synchronizer to settle.
        gpio_in      = 16'hABCD;
        gpio_buttons = 5'h1A;  // [4]=BTNC=1, [3:0]=BTND/BTNR/BTNL/BTNU=0xA
        @(posedge clk); @(posedge clk); #1;

        reg_read_en = 1;
        reg_addr = 4'h8;
        #1;

        if (reg_read_data[15:0] == 16'hABCD)
            $display("PASS: gpio_in read correctly = 0xABCD");
        else
            $display("FAIL: gpio_in expected 0xABCD, got %0h", reg_read_data[15:0]);

        if (reg_read_data[20:16] == 5'h1A)
            $display("PASS: gpio_buttons read correctly = 0x1A");
        else
            $display("FAIL: gpio_buttons expected 0x1A, got %0h", reg_read_data[20:16]);
        reg_read_en = 0;


        // --- Test 3: Write and read DIRECTION register ---
        reg_write_en = 1;
        reg_addr = 4'h0;
        reg_write_data = 32'h0000AAAA;
        @(posedge clk);
        #1;
        reg_write_en = 0;

        reg_read_en = 1;
        reg_addr = 4'h0;
        #1;

        if (reg_read_data[15:0] == 16'hAAAA)
            $display("PASS: DIRECTION register = 0xAAAA");
        else
            $display("FAIL: DIRECTION expected 0xAAAA, got %0h", reg_read_data[15:0]);
        reg_read_en = 0;

        // direction=0xAAAA, output_reg=0xFF00 → gpio_out = 0xFF00 & 0xAAAA = 0xAA00
        if (gpio_out == 16'hAA00)
            $display("PASS: gpio_out gated by direction = 0xAA00");
        else
            $display("FAIL: gpio_out gated expected 0xAA00, got %0h", gpio_out);


        // --- Test 4: Reset behavior ---
        rst_n = 0;
        @(posedge clk); #1;
        if (gpio_out == 16'b0)
            $display("PASS: gpio_out = 0 after reset");
        else
            $display("FAIL: gpio_out expected 0 after reset, got %0h", gpio_out);

        $display("All GPIO tests completed.");
        $finish;
    end

endmodule