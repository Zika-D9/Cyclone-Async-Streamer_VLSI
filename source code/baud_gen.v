module baud_gen #(
    parameter CLK_FREQ = 10_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire clk,
    input  wire rst_n,
    input  wire en,   
    output reg  tick
);

    localparam BIT_TIMER_MAX = CLK_FREQ / BAUD_RATE; 
    localparam TIMER_WIDTH   = $clog2(BIT_TIMER_MAX);

    reg [TIMER_WIDTH-1:0] baud_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= 0;
            tick     <= 1'b0;
        end else begin
            if (en) begin
                if (baud_cnt == BIT_TIMER_MAX - 1) begin
                    baud_cnt <= 0;
                    tick     <= 1'b1;
                end else begin
                    baud_cnt <= baud_cnt + 1;
                    tick     <= 1'b0;
                end
            end else begin
                baud_cnt <= 0;
                tick     <= 1'b0;
            end
        end
    end

endmodule