module TwoFF_Sync #(
    parameter WIDTH = 6
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] ptr_in,
    output reg  [WIDTH-1:0] ptr_out
);
    reg [WIDTH-1:0] sync_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= 0;
            ptr_out  <= 0;
        end else begin
            sync_reg <= ptr_in;
            ptr_out  <= sync_reg;
        end
    end
endmodule