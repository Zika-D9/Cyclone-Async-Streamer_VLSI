module rd_domain #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                   rclk,             
    input  wire                   rrst_n,           
    input  wire                   rd_en,
    input  wire [ADDR_WIDTH:0]    wr_ptr_gray_sync, // Synchronized from the write domain
    output wire [ADDR_WIDTH-1:0]  rd_addr,          // Goes to memory (fifo_mem)
    output reg  [ADDR_WIDTH:0]    rd_ptr_gray,      // Goes to the synchronizer in the write domain
    output reg                    rempty            
);

    reg  [ADDR_WIDTH:0] rd_ptr_bin;

    // Combinational logic for "next state" calculation
    wire [ADDR_WIDTH:0] rb_next; // Read Binary Next
    wire [ADDR_WIDTH:0] rg_next; // Read Gray Next
    wire                empty_val;

    // 1. Next address calculation (Look-Ahead)
    // -----------------------------------------------------------------
    // Increment the pointer only if read is enabled and the FIFO is not empty
    assign rb_next = rd_ptr_bin + (rd_en & ~rempty); 

    // Convert the *next* address to Gray code
    assign rg_next = rb_next ^ (rb_next >> 1);

    // 2. Future Empty flag calculation
    // -----------------------------------------------------------------
    // The FIFO is empty when the next read Gray pointer exactly matches
    // the synchronized write Gray pointer (all bits are identical).
    assign empty_val = (rg_next == wr_ptr_gray_sync);

    // 3. Register update (clean and synchronous)
    // -----------------------------------------------------------------
    always @(posedge rclk or negedge rrst_n) begin   
        if (!rrst_n) begin                           
            rd_ptr_bin  <= {ADDR_WIDTH+1{1'b0}};
            rd_ptr_gray <= {ADDR_WIDTH+1{1'b0}}; // Outputs cleanly from a register!
            rempty      <= 1'b1;                 // CRITICAL: FIFO is empty on reset! 
        end else begin
            rd_ptr_bin  <= rb_next;
            rd_ptr_gray <= rg_next;
            rempty      <= empty_val;            // Asserted ahead of time, preventing Underflow 
        end
    end

    // 4. Extract memory address (without the MSB used for full/empty logic)
    // -----------------------------------------------------------------
    assign rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];

endmodule