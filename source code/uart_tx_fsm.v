module uart_tx_fsm (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        baud_tick,  
    input  wire        fifo_empty,
    input  wire [15:0] fifo_data,
    
    output reg         fifo_rinc,
    output reg         tx_serial,
    output reg         tx_busy
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0]  state;
    reg [15:0] shift_reg;
    reg [3:0]  bit_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tx_serial <= 1'b1;
            tx_busy   <= 1'b0;
            fifo_rinc <= 1'b0;
            shift_reg <= 16'd0;
            bit_cnt   <= 4'd0;
        end else begin
            
            fifo_rinc <= 1'b0; // Default pulse

            case (state)
                IDLE: begin
                    tx_serial <= 1'b1;
                    if (!fifo_empty) begin
                        tx_busy   <= 1'b1;
                        shift_reg <= fifo_data;
                        fifo_rinc <= 1'b1;
                        state     <= START;
                    end else begin
                        tx_busy   <= 1'b0;
                    end
                end

                START: begin
                    tx_serial <= 1'b0;
                    if (baud_tick) begin
                        state   <= DATA;
                        bit_cnt <= 4'd0;
                    end
                end

                DATA: begin
                    tx_serial <= shift_reg[0];
                    if (baud_tick) begin
                        shift_reg <= {1'b0, shift_reg[15:1]};
                        if (bit_cnt == 4'd15) begin
                            state <= STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end

                STOP: begin
                    tx_serial <= 1'b1;
                    if (baud_tick) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule