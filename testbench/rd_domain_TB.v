`timescale 1ns / 1ps

module rd_domain_TB;

    // Parameters matching the UUT (Depth of 16)
    localparam ADDR_WIDTH_TB = 4;

    // Input signals (Registers in TB)
    reg  rclk_TB;
    reg  rrst_n_TB;
    reg  rd_en_TB;
    reg  [ADDR_WIDTH_TB:0] wr_ptr_gray_sync_TB; // Write pointer arriving from the write domain

    // Output signals (Wires in TB)
    wire [ADDR_WIDTH_TB-1:0] rd_addr_TB;
    wire [ADDR_WIDTH_TB:0]   rd_ptr_gray_TB;
    wire rempty_TB;

    // Instantiate the Unit Under Test (UUT)
    rd_domain #(
        .ADDR_WIDTH(ADDR_WIDTH_TB)
    ) uut (
        .rclk(rclk_TB),
        .rrst_n(rrst_n_TB),
        .rd_en(rd_en_TB),
        .wr_ptr_gray_sync(wr_ptr_gray_sync_TB),
        .rd_addr(rd_addr_TB),
        .rd_ptr_gray(rd_ptr_gray_TB),
        .rempty(rempty_TB)
    );

    // Clock Generation (Simulating a slower read clock, e.g., 10MHz)
    always #50 rclk_TB = ~rclk_TB;

    initial begin
        // --- Phase 1: System Initialization ---
        rclk_TB = 1'b0;
        rrst_n_TB = 1'b0; // Active low reset
        rd_en_TB = 1'b0;
        
        // Simulate an empty FIFO (Write pointer is at 0)
        wr_ptr_gray_sync_TB = 5'b00000; 

        // Hold reset for 2 clock cycles
        repeat(2) @(posedge rclk_TB);
        rrst_n_TB = 1'b1; // Release reset
        @(posedge rclk_TB);

        // --- Phase 2: Test Underflow Protection ---
        // Try to read while the FIFO is empty. 
        // The pointer should NOT advance, and 'rempty' should remain 1.
        rd_en_TB = 1'b1;
        repeat(2) @(posedge rclk_TB);
        rd_en_TB = 1'b0;
        @(posedge rclk_TB);

        // --- Phase 3: Simulate Write operation from the fast domain ---
        // The write domain writes 3 items.
        // Write Binary Pointer moves to 3 -> Gray code: 00010
        wr_ptr_gray_sync_TB = 5'b00010; 
        
        // Wait and observe the 'rempty' flag de-asserting (dropping to 0)
        repeat(2) @(posedge rclk_TB);

        // --- Phase 4: Read the data until empty ---
        // Enable read for 4 cycles. Since there are only 3 items, 
        // it should read 3 times and then automatically block the 4th read.
        rd_en_TB = 1'b1;
        repeat(4) @(posedge rclk_TB);
        
        rd_en_TB = 1'b0;
        repeat(2) @(posedge rclk_TB);

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
        $display(" Time | rd_en | rd_addr | rd_ptr_gray | wr_ptr_gray_sync || rempty ");
        $display("-------------------------------------------------------------------");
        $monitor("%5t |   %b   |   %2d    |    %b    |      %b      ||   %b   ", 
                 $time, rd_en_TB, rd_addr_TB, rd_ptr_gray_TB, wr_ptr_gray_sync_TB, rempty_TB);
    end

endmodule