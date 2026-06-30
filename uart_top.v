module uart_top #(
    parameter CLK_FREQ = 10_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk_slow,
    input  wire        rst_n,
    input  wire        fifo_empty,
    input  wire [15:0] fifo_data,
    
    output wire        fifo_rinc,
    output wire        tx_serial,
    output wire        tx_busy
);

    wire baud_tick;

    baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen_inst (
        .clk   (clk_slow),
        .rst_n (rst_n),
        .en    (tx_busy),  
        .tick  (baud_tick)
    );

 
    uart_tx_fsm fsm_inst (
        .clk        (clk_slow),
        .rst_n      (rst_n),
        .baud_tick  (baud_tick),
        .fifo_empty (fifo_empty),
        .fifo_data  (fifo_data),
        .fifo_rinc  (fifo_rinc),
        .tx_serial  (tx_serial),
        .tx_busy    (tx_busy)
    );

endmodule