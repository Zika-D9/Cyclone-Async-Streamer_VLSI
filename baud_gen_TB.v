`timescale 1ns / 1ps

module baud_gen_TB;

    // -----------------------------------------------------------------
    // Parameters (Scaled down for faster simulation)
    // -----------------------------------------------------------------
    // We set CLK_FREQ to 1000 and BAUD_RATE to 100.
    // BIT_TIMER_MAX = 1000 / 100 = 10 clock cycles per tick.
    localparam CLK_FREQ_TB  = 1000;
    localparam BAUD_RATE_TB = 100;

    reg  clk_TB;
    reg  rst_n_TB;
    reg  en_TB;
    wire tick_TB;

    baud_gen #(
        .CLK_FREQ(CLK_FREQ_TB),
        .BAUD_RATE(BAUD_RATE_TB)
    ) uut (
        .clk   (clk_TB),
        .rst_n (rst_n_TB),
        .en    (en_TB),
        .tick  (tick_TB)
    );

    // -----------------------------------------------------------------
    // Clock Generation (100ns period -> 10MHz equivalent for this test)
    // -----------------------------------------------------------------
    always #50 clk_TB = ~clk_TB;

    // -----------------------------------------------------------------
    // Main Test Stimulus
    // -----------------------------------------------------------------
    initial begin
        // --- Phase 1: System Reset ---
        clk_TB   = 1'b0;
        rst_n_TB = 1'b0;
        en_TB    = 1'b0;
        
        // Hold reset for a few cycles
        repeat(2) @(posedge clk_TB);
        rst_n_TB = 1'b1;
        @(posedge clk_TB);

        // --- Phase 2: Enable Baud Generator ---
        // We expect to see a 'tick' pulse every 10 clock cycles.
        en_TB = 1'b1;
        
        // Wait long enough to observe 3 full tick cycles (30 clocks)
        repeat(32) @(posedge clk_TB);

        // --- Phase 3: Interrupt (Disable) ---
        // Disabling 'en' should immediately reset the internal counter to 0.
        en_TB = 1'b0;
		  $display("  Time  | rst_n |  en  || internal_cnt | tick ");
        repeat(5) @(posedge clk_TB);

        // --- Phase 4: Resume ---
        // Re-enabling should start counting cleanly from 0 again.
        en_TB = 1'b1;
        repeat(15) @(posedge clk_TB);

        // --- End of Simulation ---
        en_TB = 1'b0;
        repeat(2) @(posedge clk_TB);
        
        $display("========================================");
        $display("        BAUD GEN SIMULATION COMPLETE    ");
        $display("========================================");
        $stop;
    end

    // -----------------------------------------------------------------
    // Console Monitor
    // -----------------------------------------------------------------
    initial begin
        $display("  Time  | rst_n |  en  || internal_cnt | tick ");
        $display("------------------------------------------------");
        // Using hierarchical path (uut.baud_cnt) to monitor the internal counter
        $monitor("%7t |   %b   |  %b   ||      %2d      |  %b  ", 
                 $time, rst_n_TB, en_TB, uut.baud_cnt, tick_TB);
    end

endmodule