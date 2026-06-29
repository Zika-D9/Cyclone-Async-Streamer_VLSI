module wr_domain #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                   wclk,
    input  wire                   wrst_n,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH:0]    rd_ptr_gray_sync, // Synchronized from the read domain
    output wire [ADDR_WIDTH-1:0]  wr_addr,          // Goes to memory (fifo_mem)
    output reg  [ADDR_WIDTH:0]    wr_ptr_gray,      // Goes to the synchronizer in the read domain
    output reg                    wfull
);

    reg  [ADDR_WIDTH:0] wr_ptr_bin;
    
    // Combinational logic for "next state" calculation
    wire [ADDR_WIDTH:0] wb_next; // Write Binary Next
    wire [ADDR_WIDTH:0] wg_next; // Write Gray Next
    wire                full_val;

    // 1. Next address calculation (Look-Ahead)
    // -----------------------------------------------------------------
    // Increment the pointer only if write is enabled and the FIFO is not full
    assign wb_next = wr_ptr_bin + (wr_en & ~wfull);
    
    // Convert the *next* address to Gray code
    assign wg_next = wb_next ^ (wb_next >> 1);

    // 2. Future Full flag calculation
    // -----------------------------------------------------------------
    // Compare the next Gray code with the synchronized read pointer (top 2 MSBs inverted)
    assign full_val = (wg_next == {~rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1], 
                                    rd_ptr_gray_sync[ADDR_WIDTH-2:0]});

    // 3. Register update (clean and synchronous)
    // -----------------------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr_bin  <= {ADDR_WIDTH+1{1'b0}};
            wr_ptr_gray <= {ADDR_WIDTH+1{1'b0}}; // Now outputs cleanly from a register!
            wfull       <= 1'b0;
        end else begin
            wr_ptr_bin  <= wb_next;
            wr_ptr_gray <= wg_next;
            wfull       <= full_val;     // Asserted ahead of time, preventing Overflow
        end
    end

    // 4. Extract memory address (without the MSB which is only used for Full/Empty logic)
    // -----------------------------------------------------------------
    assign wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];

endmodule