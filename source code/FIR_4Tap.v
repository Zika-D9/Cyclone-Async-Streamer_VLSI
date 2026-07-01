module FIR_4Tap (data_in, valid_in, gated_clk_fast, rst_n, data_out, valid_out);
input [7:0] data_in;
input valid_in, gated_clk_fast, rst_n;
output [15:0] data_out;
output valid_out;

reg [15:0] data_out; 
reg valid_out;

reg [15:0] X [3:0];

always @(posedge gated_clk_fast) begin
    if (rst_n == 1'b0) begin
	     X[0] <= 16'b0;
		  X[1] <= 16'b0;
		  X[2] <= 16'b0;
		  X[3] <= 16'b0;
		  valid_out <= 1'b0;
		  data_out <= 16'b0;
	end
		  
	 else if (valid_in == 1'b1) begin
        X[0]      <= data_in;
        X[1]      <= X[0];
        X[2]      <= X[1];
        X[3]      <= X[2];
        valid_out <= 1'b1;
        
        // Math is done inside the clocked block
        data_out  <= (X[0] * 1) + (X[1] * 2) + (X[2] * 3) + (X[3] * 4); 
    end else begin
        valid_out <= 1'b0;
    end
end

endmodule