`timescale 1ns / 1ps

module tb_FIR_4Tap;

    // -------------------------------------------
    // 1. Signal Declarations
    // -------------------------------------------
    // Inputs to UUT are declared as 'reg'
    reg [7:0]  tb_data_in;
    reg        tb_valid_in;
    reg        tb_clk;
    reg        tb_rst_n; // Added reset signal
    
    // Outputs from UUT are declared as 'wire'
    wire [15:0] tb_data_out;
    wire        tb_valid_out;

    // -------------------------------------------
    // 2. Instantiate the Unit Under Test (UUT)
    // -------------------------------------------
    FIR_4Tap uut (
        .data_in(tb_data_in), 
        .valid_in(tb_valid_in), 
        .gated_clk_fast(tb_clk), 
        .rst_n(tb_rst_n),         // Connected reset port
        .data_out(tb_data_out), 
        .valid_out(tb_valid_out)
    );

    // -------------------------------------------
    // 3. Clock Generation
    // -------------------------------------------
    // Generate a clock with a 10ns period (100 MHz)
    always #5 tb_clk = ~tb_clk;

    // -------------------------------------------
    // 4. Stimulus Block
    // -------------------------------------------
    initial begin
        // Initialize Signals
        tb_clk      = 1'b0;
        tb_valid_in = 1'b0;
        tb_data_in  = 8'd0;
        tb_rst_n    = 1'b0; // Start with reset ASSERTED (active low)

        // --- PHASE 1: System Reset ---
        // Hold reset for a couple of clock cycles to ensure all registers clear
        repeat(2) @(posedge tb_clk);
        tb_rst_n = 1'b1; // De-assert reset, system is now ready
        
        // Wait one cycle before injecting data
        @(posedge tb_clk);

        // --- PHASE 2: Impulse Response Test ---
        // Feed a single '10' followed by '0's. 
        // Because of the 1-cycle pipeline delay in the math, the output will trail.
        // Expected data_out sequence: 0 -> 10 -> 20 -> 30 -> 40 -> 0
        tb_valid_in = 1'b1;
        tb_data_in  = 8'd10; 
        
        @(posedge tb_clk);
        tb_data_in  = 8'd0; // Feed zeros to push the '10' through the taps
        
        // Wait for the impulse to travel through all 4 taps
        repeat(5) @(posedge tb_clk);

        // --- PHASE 3: Valid Enable / Pause Test ---
        // Ensure that deasserting valid_in pauses the shifting and ignores bad data
        tb_data_in = 8'd5;
        @(posedge tb_clk);
        
        tb_valid_in = 1'b0;  // PAUSE the filter!
        tb_data_in  = 8'd99; // This garbage data should NOT be clocked in
        repeat(3) @(posedge tb_clk); // Wait a few cycles while paused
        
        tb_valid_in = 1'b1;  // RESUME the filter
        tb_data_in  = 8'd5;
        repeat(5) @(posedge tb_clk);

        // End Simulation
        $display("========================================");
        $display("          SIMULATION COMPLETE           ");
        $display("========================================");
        $stop;
    end

    // -------------------------------------------
    // 5. Console Monitor
    // -------------------------------------------
    // This prints a clean table row to the console every time a variable changes
    initial begin
        $display(" Time | rst_n | valid_in | data_in || valid_out | data_out");
        $display("----------------------------------------------------------");
        $monitor("%5t |   %b   |    %b     |   %3d   ||     %b     |   %4d", 
                 $time, tb_rst_n, tb_valid_in, tb_data_in, tb_valid_out, tb_data_out);
    end

endmodule