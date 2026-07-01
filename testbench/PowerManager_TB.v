`timescale 1ns / 1ps

module PowerManager_TB;

reg [7:0] data_in_TB;
reg valid_in_TB;
reg clk_TB;
wire clk_en_TB;


PowerManager uut (

.data_in(data_in_TB),
.valid_in(valid_in_TB),
.clk(clk_TB),
.clk_en(clk_en_TB)

);


always #5 clk_TB = ~clk_TB;

initial begin
	data_in_TB = 8'd0;
	valid_in_TB = 1'b0;
	clk_TB = 1'b0;


	repeat(2) @(posedge clk_TB);

	valid_in_TB = 1'b1;
	data_in_TB = 8'd5;


	@(posedge clk_TB);

	valid_in_TB = 1'b1;
	data_in_TB = 8'd7;


	@(posedge clk_TB);

	valid_in_TB = 1'b0;
	data_in_TB = 8'd10;


	repeat(15) @(posedge clk_TB);

	valid_in_TB = 1'b1;

	// End Simulation
	$display("========================================");
	$display("          SIMULATION COMPLETE           ");
	$display("========================================");
	$stop;
end


// -------------------------------------------
// Console Monitor
// -------------------------------------------
 // This prints a clean table row to the console every time a variable changes
initial begin
	$display(" Time | valid_in | data_in || clk_en");
   $display("----------------------------------------------------------");
   $monitor("%5t |    %b     |   %3d   ||   %b", $time, valid_in_TB, data_in_TB, clk_en_TB);
end

endmodule











