module async_fifo_top #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    // Write Interface (Fast Domain)
    input  wire                   wclk,
    input  wire                   wrst_n,
    input  wire                   wr_en,
    input  wire [DATA_WIDTH-1:0]  wdata,
    output wire                   wfull,

    // Read Interface (Slow Domain)
    input  wire                   rclk,
    input  wire                   rrst_n,
    input  wire                   rd_en,
    output wire [DATA_WIDTH-1:0]  rdata,
    output wire                   rempty
);

    // Interconnect Wires
    wire [ADDR_WIDTH-1:0] wr_addr, rd_addr;
    wire [ADDR_WIDTH:0]   wr_ptr_gray, rd_ptr_gray;
    wire [ADDR_WIDTH:0]   wr_ptr_gray_sync, rd_ptr_gray_sync;

    // -----------------------------------------------------------------
    // Instantiation: Memory Array (Dual-Port RAM)
    // -----------------------------------------------------------------
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) mem_inst (
        .wclk    (wclk),
        .wr_en   (wr_en),
        .wfull   (wfull),
        .wr_addr (wr_addr),
        .wdata   (wdata),
        .rd_addr (rd_addr),
        .rdata   (rdata)
    );

    // -----------------------------------------------------------------
    // Instantiation: Write Domain Control
    // -----------------------------------------------------------------
    wr_domain #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) wr_domain_inst (
        .wclk            (wclk),
        .wrst_n          (wrst_n),
        .wr_en           (wr_en),
        .rd_ptr_gray_sync(rd_ptr_gray_sync), // Arrives from synchronizer
        .wr_addr         (wr_addr),
        .wr_ptr_gray     (wr_ptr_gray),
        .wfull           (wfull)
    );

    // -----------------------------------------------------------------
    // Instantiation: Read Domain Control
    // -----------------------------------------------------------------
    rd_domain #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) rd_domain_inst (
        .rclk            (rclk),
        .rrst_n          (rrst_n),
        .rd_en           (rd_en),
        .wr_ptr_gray_sync(wr_ptr_gray_sync), // Arrives from synchronizer
        .rd_addr         (rd_addr),
        .rd_ptr_gray     (rd_ptr_gray),
        .rempty          (rempty)
    );

    // -----------------------------------------------------------------
    // Synchronizer: Pass Read Pointer to Write Domain (rclk -> wclk)
    // -----------------------------------------------------------------
    TwoFF_Sync #(
        .WIDTH(ADDR_WIDTH + 1)
    ) rd_to_wr_sync (
        .clk     (wclk),             // Clocked by destination domain (Write)
        .rst_n   (wrst_n),           // Reset by destination domain
        .ptr_in  (rd_ptr_gray),      // Original gray pointer from read domain
        .ptr_out (rd_ptr_gray_sync)  // Synchronized pointer out
    );

    // -----------------------------------------------------------------
    // Synchronizer: Pass Write Pointer to Read Domain (wclk -> rclk)
    // -----------------------------------------------------------------
    TwoFF_Sync #(
        .WIDTH(ADDR_WIDTH + 1)
    ) wr_to_rd_sync (
        .clk     (rclk),             // Clocked by destination domain (Read)
        .rst_n   (rrst_n),           // Reset by destination domain
        .ptr_in  (wr_ptr_gray),      // Original gray pointer from write domain
        .ptr_out (wr_ptr_gray_sync)  // Synchronized pointer out
    );

endmodule