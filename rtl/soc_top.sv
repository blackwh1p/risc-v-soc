// ============================================================
// Module  : soc_top
// Purpose : Top-level SoC module
//           Instantiates CPU, memories, and all peripherals
//           This is the root module for Vivado synthesis
// ============================================================
module soc_top (
    // Nexys A7 100MHz system clock
    input  logic        clk_100mhz,

    // Nexys A7 CPU reset button (active low)
    input  logic        rst_n,

    // UART pins (connected to USB-UART bridge on Nexys A7)
    output logic        uart_tx,
    input  logic        uart_rx,

    // LED outputs (16 LEDs on Nexys A7)
    output logic [15:0] leds,

    // Switch inputs (16 switches on Nexys A7)
    input  logic [15:0] switches,

    // Button inputs (5 buttons on Nexys A7)
    input  logic [4:0]  buttons
);

    // CPU memory interface
    logic [31:0] imem_addr, imem_data;
    logic [31:0] dmem_addr, dmem_write_data, dmem_read_data, dmem_read_data_raw;
    logic        dmem_write_en, dmem_read_en;

    // Peripheral MMIO interface
    logic        mmio_write_en, mmio_read_en;
    logic [3:0]  mmio_reg_addr;
    logic [31:0] mmio_write_data, mmio_read_data;

    // Peripheral select signals
    logic        uart_sel, timer_sel, gpio_sel;

    // Peripheral read data
    logic [31:0] uart_read_data, timer_read_data, gpio_read_data;

    // Interrupt signals
    logic        timer_interrupt;

    // Select which peripheral based on address
    assign uart_sel  = (dmem_addr[31:28] == 4'h4) && (dmem_addr[15:12] == 4'h0);
    assign timer_sel = (dmem_addr[31:28] == 4'h4) && (dmem_addr[15:12] == 4'h1);
    assign gpio_sel  = (dmem_addr[31:28] == 4'h4) && (dmem_addr[15:12] == 4'h2);

    // Route MMIO signals to correct peripheral
    assign mmio_write_en  = dmem_write_en;
    assign mmio_read_en   = dmem_read_en;
    assign mmio_reg_addr  = dmem_addr[3:0];
    assign mmio_write_data = dmem_write_data;

    cpu u_cpu (
    .clk              (clk_100mhz),
    .rst_n            (rst_n),
    .imem_addr        (imem_addr),
    .imem_data        (imem_data),
    .dmem_addr        (dmem_addr),
    .dmem_write_data  (dmem_write_data),
    .dmem_write_en    (dmem_write_en),
    .dmem_read_en     (dmem_read_en),
    .dmem_read_data   (dmem_read_data)
    );

    imem #(
    .MEM_DEPTH (4096),
    .MEM_FILE  ("sw/tests/test_imem.mem")
    ) u_imem (
        .clk  (clk_100mhz),
        .addr (imem_addr),
        .data (imem_data)
    );

    dmem #(
        .MEM_DEPTH (4096)
        ) u_dmem (
            .clk  (clk_100mhz),
            .read_en (dmem_read_en),
            .addr (dmem_addr),
            .read_data (dmem_read_data_raw),
            .write_en (dmem_write_en),
            .byte_enable (4'b1111),
            .write_data (dmem_write_data)
        );

    gpio u_gpio (
        .clk (clk_100mhz),
        .rst_n (rst_n),

        .reg_write_en (mmio_write_en && gpio_sel),
        .reg_read_en (mmio_read_en && gpio_sel),
        .reg_addr (mmio_reg_addr),
        .reg_write_data (mmio_write_data),
        .reg_read_data (gpio_read_data),

        .gpio_out (leds),
        .gpio_in (switches)
    );

    timer u_timer (
        .clk (clk_100mhz),
        .rst_n (rst_n),

        .reg_write_en (mmio_write_en && timer_sel),
        .reg_read_en (mmio_read_en && timer_sel),
        .reg_addr (mmio_reg_addr),
        .reg_write_data (mmio_write_data),
        .reg_read_data (timer_read_data),

        .timer_interrupt (timer_interrupt)
    );

    uart u_uart (
        .clk (clk_100mhz),
        .rst_n (rst_n),

        .reg_write_en (mmio_write_en && uart_sel),
        .reg_read_en (mmio_read_en && uart_sel),
        .reg_addr (mmio_reg_addr),
        .reg_write_data (mmio_write_data),
        .reg_read_data (uart_read_data),

        .uart_tx (uart_tx),
        .uart_rx (uart_rx)
    );

    // Combine peripheral read data
    always @(*) begin
        mmio_read_data = 32'b0;
        if (uart_sel)       mmio_read_data = uart_read_data;
        else if (timer_sel) mmio_read_data = timer_read_data;
        else if (gpio_sel)  mmio_read_data = gpio_read_data;
    end

    // Route read data back to CPU
    assign dmem_read_data = (dmem_addr[31:28] == 4'h4) ? mmio_read_data : dmem_read_data_raw;

endmodule