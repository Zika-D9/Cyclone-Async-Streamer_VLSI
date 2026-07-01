`timescale 1ns / 1ps

module system_top_TB;

    // Parameters for simulation acceleration
    localparam UART_CLK_FREQ_TB  = 10_000_000;
    localparam UART_BAUD_RATE_TB = 9600;
    localparam FIFO_DEPTH_TB     = 32;

    // Top interface signals declaration
    reg        clk_fast_TB;
    reg        clk_slow_TB;
    reg        rst_n_TB;
    reg [7:0]  data_in_TB;
    reg        valid_in_TB;

    wire       tx_serial_TB;
    wire       tx_busy_TB;
    wire       wfull_TB;
    wire       rempty_TB;

    // Internal variables for automated verification (Scoreboard)
    integer i;
    reg [15:0] expected_data [0:15]; // Queue for storing expected FIR results
    integer    expected_count = 0;
    integer    read_count = 0;
    reg [15:0] reconstructed_data;
	 
    // -----------------------------------------------------------------
    // Unit Under Test (UUT) Instantiation
    // -----------------------------------------------------------------
    system_top #(
        .UART_CLK_FREQ(UART_CLK_FREQ_TB),
        .UART_BAUD_RATE(UART_BAUD_RATE_TB),
        .FIFO_DEPTH(FIFO_DEPTH_TB)
    ) uut (
        .clk_fast  (clk_fast_TB),
        .clk_slow  (clk_slow_TB),
        .rst_n     (rst_n_TB),
        .data_in   (data_in_TB),
        .valid_in  (valid_in_TB),
        .tx_serial (tx_serial_TB),
        .tx_busy   (tx_busy_TB),
        .wfull     (wfull_TB),
        .rempty    (rempty_TB)
    );

    // -----------------------------------------------------------------
    // Asynchronous Clock Generation
    // -----------------------------------------------------------------
    // Fast clock: 10ns period (100MHz)
    always #5 clk_fast_TB = ~clk_fast_TB;
    
    // Slow clock: 50ns period (10MHz)
    always #50 clk_slow_TB = ~clk_slow_TB;

    // -----------------------------------------------------------------
    // Main Test Stimulus
    // -----------------------------------------------------------------
    initial begin
        // System Reset
        clk_fast_TB = 0;
        clk_slow_TB = 0;
        rst_n_TB    = 0;
        data_in_TB  = 8'd0;
        valid_in_TB = 0;

        $display("=========================================================");
        $display("      SYSTEM TOP FULL DATAPATH VERIFICATION STARTED      ");
        $display("=========================================================\n");

        #100 rst_n_TB = 1; 
        #50;
        
		  valid_in_TB = 1;
		  
		  $display("\n");
        $display("      FIRST ITERATION      ");
        $display("=========================================================");
		  
        // Inject 4 consecutive values into the FIR filter
        repeat (2) @(posedge clk_fast_TB); // Adding 2 clk for the ALTCLKCTRL delay
        data_in_TB = 8'd10; @(posedge clk_fast_TB);
        data_in_TB = 8'd10; @(posedge clk_fast_TB);
        data_in_TB = 8'd10; @(posedge clk_fast_TB);
        data_in_TB = 8'd10; @(posedge clk_fast_TB);
		  data_in_TB = 8'd0; @(posedge clk_fast_TB);
		  
		  repeat (4) @(posedge clk_fast_TB);
		  
        valid_in_TB = 0; // End of data injection

        // Wait until data reaches the FIFO read side
        wait (rempty_TB == 1'b0); 
        
        // Wait until the FIFO is completely empty (everything sent to UART)
        wait (rempty_TB == 1'b1);
        
        // Wait until UART finishes transmitting the last word
        wait (tx_busy_TB == 1'b0);
        
		  //--------------------------------------------------------------------------------//
		  
        valid_in_TB = 1;
			
		  $display("\n");
        $display("      SECOND ITERATION      ");
        $display("=========================================================");
			
        // Inject 4 consecutive values into the FIR filter
        repeat (2) @(posedge clk_fast_TB); // Adding 2 clk for the ALTCLKCTRL delay
        data_in_TB = 8'd10; @(posedge clk_fast_TB);
        data_in_TB = 8'd20; @(posedge clk_fast_TB);
        data_in_TB = 8'd30; @(posedge clk_fast_TB);
        data_in_TB = 8'd40; @(posedge clk_fast_TB);
		  data_in_TB = 8'd0; @(posedge clk_fast_TB);
		  
        valid_in_TB = 0; // End of data injection
		  
		          // Wait until data reaches the FIFO read side
        wait (rempty_TB == 1'b0); 
        
        // Wait until the FIFO is completely empty (everything sent to UART)
        wait (rempty_TB == 1'b1);
        
        // Wait until UART finishes transmitting the last word
        wait (tx_busy_TB == 1'b0);
		  
		  valid_in_TB = 1;
		  @(posedge clk_fast_TB);
		  valid_in_TB = 0;
		  
		  $display("\n=========================================================");
        $display("                 POWER MANAGER TEST:                     ");
        $display("=========================================================");
		  
		  repeat (2) @(posedge clk_fast_TB); // Adding 2 clk for the ALTCLKCTRL delay
		  for (i=0 ; i<15; i=i+1) begin
				$display(" Value of gated_clk_fast: %b", uut.fir_inst.gated_clk_fast);
				@(posedge clk_fast_TB);
		  end
		  
        #500;
        $display("\n=========================================================");
        $display("                 SIMULATION COMPLETE                     ");
        $display("=========================================================");
        $stop;
    end

    // -----------------------------------------------------------------
    // Checker 1: Sample FIR output and store in queue
    // -----------------------------------------------------------------
    always @(posedge clk_fast_TB) begin
        if (uut.fir_valid_out) begin
            expected_data[expected_count] = uut.fir_data_out;
            $display("Time: %7t | FIR Processed Data: %4d | Stored to Expected Queue", 
                     $time, uut.fir_data_out);
            expected_count = expected_count + 1;
        end
    end

    // -----------------------------------------------------------------
    // Checker 2: Monitor UART and compare data
    // -----------------------------------------------------------------
    always @(posedge clk_slow_TB) begin
        // Internal access to UART baud ticks
        if (uut.uart_tx_inst.baud_tick) begin
            
            // Collect bits into a 16-bit word
            if (uut.uart_tx_inst.fsm_inst.state == 3'd2) begin 
                reconstructed_data[uut.uart_tx_inst.fsm_inst.bit_cnt] <= tx_serial_TB;
            end
            
            // At the end of transmission (Stop bit), compare with the queued expected word
            if (uut.uart_tx_inst.fsm_inst.state == 3'd3) begin 
                if (reconstructed_data === expected_data[read_count]) begin
                    $display("Time: %7t | >>> [PASS] UART Transmitted: %4d (Matches FIR)", 
                             $time, reconstructed_data);
                end else begin
                    $display("Time: %7t | >>> [FAIL] UART Transmitted: %4d (Expected: %4d)", 
                             $time, reconstructed_data, expected_data[read_count]);
                end
                read_count = read_count + 1;
            end
        end
    end

	 initial begin
    $dumpfile("simulation_dump.vcd"); // the file will be in the work dir
    $dumpvars(0, system_top_TB);       
	 end

endmodule