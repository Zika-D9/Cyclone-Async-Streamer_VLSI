`timescale 1ns / 1ps

module wr_domain_TB;

    // Parameters matching the UUT (Depth of 16)
    localparam ADDR_WIDTH_TB = 4;

    // Input signals (Registers in TB)
    reg  wclk_TB;
    reg  wrst_n_TB;
    reg  wr_en_TB;
    reg  [ADDR_WIDTH_TB:0] rd_ptr_gray_sync_TB; 

    // Output signals (Wires in TB)
    wire [ADDR_WIDTH_TB-1:0] wr_addr_TB;
    wire [ADDR_WIDTH_TB:0]   wr_ptr_gray_TB;
    wire wfull_TB;

    // Instantiate the Unit Under Test (UUT)
    wr_domain #(
        .ADDR_WIDTH(ADDR_WIDTH_TB)
    ) uut (
        .wclk(wclk_TB),
        .wrst_n(wrst_n_TB),
        .wr_en(wr_en_TB),
        .rd_ptr_gray_sync(rd_ptr_gray_sync_TB),
        .wr_addr(wr_addr_TB),
        .wr_ptr_gray(wr_ptr_gray_TB),
        .wfull(wfull_TB)
    );

    // Clock Generation (10ns period)
    always #5 wclk_TB = ~wclk_TB;

    initial begin
        // --- Phase 1: System Initialization ---
        wclk_TB   = 1'b0;
        wrst_n_TB = 1'b0; // Active low reset
        wr_en_TB  = 1'b0;
        
        // Simulate an empty FIFO (Read pointer is at 0)
        rd_ptr_gray_sync_TB = 5'b00000; 

        // Hold reset for 2 clock cycles to ensure clean state
        repeat(2) @(posedge wclk_TB);
        wrst_n_TB = 1'b1; // Release reset
        @(posedge wclk_TB);

        // --- Phase 2: Fill the FIFO to Trigger 'wfull' ---
        // We will attempt to write 18 times to a FIFO of depth 16.
        // The Look-Ahead logic should block the pointer from advancing after 16 writes.
        wr_en_TB = 1'b1;
        repeat(18) @(posedge wclk_TB);

        // Disable write to observe the static full state
        wr_en_TB = 1'b0;
        repeat(3) @(posedge wclk_TB);

        // --- Phase 3: Simulate Read operation from the slow domain ---
        // Update the read pointer to simulate 2 items being read.
        // Binary: 2 -> Gray code: 00011
        rd_ptr_gray_sync_TB = 5'b00011; 
        
        // Wait and observe the 'wfull' flag de-asserting
        repeat(3) @(posedge wclk_TB);
        
        // Attempt to write again now that 2 slots have freed up
        wr_en_TB = 1'b1;
        repeat(4) @(posedge wclk_TB);

        // --- End of Simulation ---
        $display("========================================");
        $display("          SIMULATION COMPLETE           ");
        $display("========================================");
        $stop;
    end

    // -------------------------------------------
    // Console Monitor
    // -------------------------------------------
    initial begin
        $display(" Time | wr_en | wr_addr | wr_ptr_gray | rd_ptr_gray_sync || wfull ");
        $display("------------------------------------------------------------------");
        $monitor("%5t |   %b   |   %2d    |    %b    |      %b      ||   %b   ", 
                 $time, wr_en_TB, wr_addr_TB, wr_ptr_gray_TB, rd_ptr_gray_sync_TB, wfull_TB);
    end

endmodule