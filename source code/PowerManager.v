module PowerManager (data_in, valid_in, clk, clk_en);
input [7:0] data_in; // No usage 
input valid_in, clk;
output clk_en;

reg [3:0] counter = 4'd0;
reg clk_en;

always @(posedge clk) begin
	
	if (valid_in == 1'b0) begin
		if (counter < 4'd10) begin
			counter <= counter + 1'b1;
		end
	end else begin
		counter <= 4'd0;
	end
	
	if (counter >= 4'd10) begin
		clk_en <= 1'b0;
	end else begin
		clk_en <= 1'b1;
	end
	
end

endmodule