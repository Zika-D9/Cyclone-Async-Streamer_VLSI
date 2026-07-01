`timescale 1ns / 1ps

module fifo_mem_TB;

localparam DATA_WIDTH_TB = 16;
localparam DEPTH_TB = 32;
localparam ADDR_WIDTH_TB = $clog2(DEPTH_TB);

reg  wclk_TB;
reg  wr_en_TB;
reg  wfull_TB; 
reg [ADDR_WIDTH_TB-1:0] wr_addr_TB; // Head
reg [ADDR_WIDTH_TB-1:0] rd_addr_TB; 
reg [DATA_WIDTH_TB-1:0] wdata_TB;

wire [DATA_WIDTH_TB-1:0] rdata_TB;

integer i, j;

fifo_mem #(
	.DATA_WIDTH(DATA_WIDTH_TB),
	.DEPTH(DEPTH_TB),
	.ADDR_WIDTH(ADDR_WIDTH_TB)
) uut ( 
	.wclk(wclk_TB),
	.wr_en(wr_en_TB),
	.wfull(wfull_TB),
	.wr_addr(wr_addr_TB),
	.wdata(wdata_TB),
	.rd_addr(rd_addr_TB),
	.rdata(rdata_TB)

);


always #5 wclk_TB = ~wclk_TB;


initial begin

	wclk_TB = 1'b0;
	wdata_TB = {DATA_WIDTH_TB{1'b0}};
	rd_addr_TB = {ADDR_WIDTH_TB{1'b0}};
	wr_addr_TB = {ADDR_WIDTH_TB{1'b0}};
	wr_en_TB = 1'b0;
	wfull_TB = 1'b0;

	
	repeat(2) @(posedge wclk_TB);

	wdata_TB = 16'd7;
	wr_addr_TB = 5'd0;
	rd_addr_TB = 5'd0;
	wr_en_TB = 1'b1;
	wfull_TB = 1'b0;


	@(posedge wclk_TB);

	wr_en_TB = 1'b1;
	wdata_TB = 16'd6;
	wr_addr_TB = 5'd1;
	rd_addr_TB = 5'd0;
	wfull_TB = 1'b0;


	@(posedge wclk_TB);

	wdata_TB = 16'd5;
	wr_addr_TB = 5'd2;
	rd_addr_TB = 5'd2;
	wr_en_TB = 1'b0;
	wfull_TB = 1'b0;


	@(posedge wclk_TB);

	wr_en_TB = 1'b1;
	rd_addr_TB = 5'd0;

	for(i = 0; i < 32; i = i + 1) begin
            wdata_TB   = i + 10; 
            wr_addr_TB = i;      
            @(posedge wclk_TB);
			end

	wr_en_TB = 1'b0;
	wfull_TB = 1'b1;

	
	@(posedge wclk_TB);
	
	wfull_TB = 1'b0; 
        
   
    for(j = 0; j < 32; j = j + 1) begin
            rd_addr_TB = j;
            @(posedge wclk_TB); 
        end

	wr_en_TB = 1'b1;    
		  
		  
	$display("========================================");
   $display("          SIMULATION COMPLETE           ");
   $display("========================================");
   $stop;	  
		 		  
end


initial begin
        $display(" Time | wr_en | wr_addr | wdata | wfull || rd_addr | rdata ");
        $display("-----------------------------------------------------");
        $monitor("%5t |   %b   |   %2d    |%4d   |   %b  ||   %2d    |  %4d ", 
                 $time, wr_en_TB, wr_addr_TB, wdata_TB, wfull_TB, rd_addr_TB, rdata_TB);
    end

endmodule


