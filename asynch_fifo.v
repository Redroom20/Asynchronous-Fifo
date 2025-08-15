
module async_fifo_corrected
    #(
        parameter DATA_WIDTH = 8,
        parameter ADDR_WIDTH = 4  // Results in a depth of 2^ADDR_WIDTH
    )
    (
    // Write Domain Ports
    input                       wr_clk,
    input                       wr_rstn,
    input                       wr_en,
    input      [DATA_WIDTH-1:0] wr_data,
    output reg                  wr_full,

    // Read Domain Ports
    input                       rd_clk,
    input                       rd_rstn,
    input                       rd_en,
    output reg [DATA_WIDTH-1:0] rd_data,
    output reg                  rd_empty
    );

    // --- Internal Parameters and Signals ---
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;

    // Memory array
    reg [DATA_WIDTH-1:0] ram [0:FIFO_DEPTH-1];

    // Pointers and addresses
    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-1:0] rd_addr;

    // Pointers for each clock domain
    reg  [PTR_WIDTH-1:0]  wr_ptr, wr_b_ptr; // Write domain: Gray and Binary pointers
    reg  [PTR_WIDTH-1:0]  rd_ptr, rd_b_ptr; // Read domain: Gray and Binary pointers

    // Synchronized pointers
    reg  [PTR_WIDTH-1:0]  wr_sync_rd_ptr; // rd_ptr synchronized to wr_clk
    reg  [PTR_WIDTH-1:0]  rd_sync_wr_ptr; // wr_ptr synchronized to rd_clk

    // Write Clock Domain Logic

    // Combinational logic for next pointer values in write domain
    wire [PTR_WIDTH-1:0] wr_b_next = (wr_en && ~wr_full) ? (wr_b_ptr + 1'b1) : wr_b_ptr;
    wire [PTR_WIDTH-1:0] wr_g_next = (wr_b_next >> 1) ^ wr_b_next; // Binary to Gray

    // Write pointer generation and memory write operation
    always @(posedge wr_clk or negedge wr_rstn) begin
        if (~wr_rstn) begin
            wr_b_ptr <= 0;
            wr_ptr   <= 0;
        end else begin
            wr_b_ptr <= wr_b_next;
            wr_ptr   <= wr_g_next;
        end
    end

    // Write data to RAM
    always @(posedge wr_clk) begin
        if (wr_en && ~wr_full) begin
            ram[wr_addr] <= wr_data;
        end
    end

    // Address for writing to RAM
    assign wr_addr = wr_b_ptr[ADDR_WIDTH-1:0];

    // Full condition logic
    always @(posedge wr_clk or negedge wr_rstn) begin
        if (~wr_rstn) begin
            wr_full <= 1'b0;
        end else begin
            // Full when next Gray pointer matches the synchronized read pointer with MSBs inverted
            wr_full <= (wr_g_next == {~wr_sync_rd_ptr[PTR_WIDTH-1:PTR_WIDTH-2], wr_sync_rd_ptr[ADDR_WIDTH-1:0]});
        end
    end

    //  Synchronizer for read pointer (to write clock domain)
    reg [PTR_WIDTH-1:0] rd_ptr_sync1;
    always @(posedge wr_clk or negedge wr_rstn) begin
        if (~wr_rstn) begin
            rd_ptr_sync1   <= 0;
            wr_sync_rd_ptr <= 0;
        end else begin
            rd_ptr_sync1   <= rd_ptr; // Capture rd_ptr from read domain
            wr_sync_rd_ptr <= rd_ptr_sync1; // Pass through second flop
        end
    end

    //  Read Clock Domain Logic

    // Combinational logic for next pointer values in read domain
    wire [PTR_WIDTH-1:0] rd_b_next = (rd_en && ~rd_empty) ? (rd_b_ptr + 1'b1) : rd_b_ptr;
    wire [PTR_WIDTH-1:0] rd_g_next = (rd_b_next >> 1) ^ rd_b_next; // Binary to Gray

    // Read pointer generation
    always @(posedge rd_clk or negedge rd_rstn) begin
        if (~rd_rstn) begin
            rd_b_ptr <= 0;
            rd_ptr   <= 0;
        end else begin
            rd_b_ptr <= rd_b_next;
            rd_ptr   <= rd_g_next;
        end
    end

    // Registered data read from RAM
    always @(posedge rd_clk) begin
        if (rd_en && ~rd_empty) begin
            rd_data <= ram[rd_addr];
        end
    end

    // Address for reading from RAM
    assign rd_addr = rd_b_ptr[ADDR_WIDTH-1:0];

    // Empty condition logic
    always @(posedge rd_clk or negedge rd_rstn) begin
        if (~rd_rstn) begin
            rd_empty <= 1'b1;
        end else begin
            // Empty when current read pointer matches synchronized write pointer
            rd_empty <= (rd_ptr == rd_sync_wr_ptr);
        end
    end

    // Synchronizer for write pointer (to read clock domain)
    reg [PTR_WIDTH-1:0] wr_ptr_sync1;
    always @(posedge rd_clk or negedge rd_rstn) begin
        if (~rd_rstn) begin
            wr_ptr_sync1   <= 0;
            rd_sync_wr_ptr <= 0;
        end else begin
            wr_ptr_sync1   <= wr_ptr; // Capture wr_ptr from write domain
            rd_sync_wr_ptr <= wr_ptr_sync1; // Pass through second flop
        end
    end

endmodule
