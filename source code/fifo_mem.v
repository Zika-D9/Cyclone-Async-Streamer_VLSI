module fifo_mem #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH) // log2() function
)(
    input  wire                   wclk,
    input  wire                   wr_en,
    input  wire                   wfull, 
    input  wire [ADDR_WIDTH-1:0]  wr_addr, // Head
    input  wire [DATA_WIDTH-1:0]  wdata,
    
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [DATA_WIDTH-1:0]  rdata
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge wclk) begin
        if (wr_en && !wfull)
            mem[wr_addr] <= wdata;
    end

    assign rdata = mem[rd_addr];
endmodule