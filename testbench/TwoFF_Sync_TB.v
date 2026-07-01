`timescale 1ns / 1ps

module TwoFF_Sync_TB;

localparam WIDTH_TB = 5;

reg   clk_TB;
reg   rst_n_TB;
reg   [WIDTH_TB-1:0] ptr_in_TB;
wire  [WIDTH_TB-1:0] ptr_out_TB;



TwoFF_Sync #(.WIDTH(WIDTH_TB)) uut
(
.clk(clk_TB),
.rst_n(rst_n_TB),
.ptr_in(ptr_in_TB),
.ptr_out(ptr_out_TB)

);


always #5 clk_TB = ~clk_TB;


initial begin 

rst_n_TB = 1'b0;
clk_TB = 1'b0;
ptr_in_TB = {WIDTH_TB{1'b0}};


repeat(2) @(posedge clk_TB);

ptr_in_TB = 5'd1;


@(posedge clk_TB);

rst_n_TB = 1'b1;
ptr_in_TB = 5'd2;


@(posedge clk_TB);

ptr_in_TB = 5'd7;


repeat(3) @(posedge clk_TB);



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
	$display(" Time | rst_n | ptr_in || ptr_out");
   $display("----------------------------------------------------------");
   $monitor("%5t |    %b     |   %3d   ||   %3d", $time, rst_n_TB, ptr_in_TB, ptr_out_TB);
end

endmodule











