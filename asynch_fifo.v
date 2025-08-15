module async_fifo_final 
	(
	input [7:0] wr_data,
	input wr_clk,
	input wr_en,
	input wr_rstn,
	input rd_clk,
	input rd_en,
	input rd_rstn, 
	output [7:0] rd_data,
	output reg wr_full,
	output reg rd_empty
	);
	localparam DEPTH = 16;
	wire [3:0] wr_addr; 
	wire [3:0] rd_addr;
	reg [7:0] ram [0:DEPTH-1];
	//read from fifo
	assign rd_data = ram[rd_addr];
	//write to fifo
	always @(posedge wr_clk) begin
		if (wr_en && ~wr_full) ram[wr_addr] <= wr_data;
	end
	reg [4:0] wr_b, wr_ptr;
	reg [4:0] wr_gnext, wr_bnext;
	//generating next binary and gray write pointers
	always @(posedge wr_clk or negedge wr_rstn) begin
		if (~wr_rstn) begin
			wr_b <= 0;
			wr_ptr <= 0;
		end
		else begin
			wr_b <= wr_bnext;
			wr_ptr <= wr_gnext;
		end
	end
	always@(*) begin
		if (wr_en && ~wr_full) begin wr_bnext = wr_b + 5'd1; end
		else begin wr_bnext = wr_b; end
		wr_gnext = (wr_bnext>>1) ^ wr_bnext;
	end
	//To address FIFO memory
	assign wr_addr = wr_b[3:0]; 
	// FIFO full logic
	reg [4:0] wr_sync_rd_ptr;
	always @(posedge wr_clk or negedge wr_rstn) begin
		if (~wr_rstn) wr_full <= 1'b0;
		else wr_full <= (wr_gnext=={~wr_sync_rd_ptr[4:3],
	wr_sync_rd_ptr[4-2:0]});
	end
	reg [4:0] rd_b, rd_ptr;
	reg [4:0] rd_gnext, rd_bnext;
	//generating next binary and gray read pointers
	always @(posedge rd_clk or negedge rd_rstn) begin
		if (~rd_rstn) begin
			rd_b <= 0;
			rd_ptr <= 0;
		end
		else begin
			rd_b <= rd_bnext;
			rd_ptr <= rd_gnext;
		end
	end
	always@(*) begin
		if(rd_en && ~rd_empty) begin rd_bnext = rd_b + 5'd1; end
		else begin rd_bnext = rd_b; end
		rd_gnext = (rd_bnext>>1) ^ rd_bnext;
	end
	//To address FIFO memory
	assign rd_addr = rd_b[3:0]; 
	// FIFO empty logic
	reg [4:0] rd_sync_wr_ptr;
	always @(posedge rd_clk or negedge rd_rstn) begin
		if (~rd_rstn) rd_empty <= 1'b1;
		else rd_empty <= (rd_gnext == rd_sync_wr_ptr);
	end
	//two_flop_synchronizer for read
	reg [4:0] rd1_ptr;
	always @(posedge rd_clk or negedge rd_rstn) begin
		if (~rd_rstn) begin 
			wr_sync_rd_ptr <= 0;
			rd1_ptr <= 0;
		end
		else begin
			wr_sync_rd_ptr <= rd1_ptr;
			rd1_ptr <= rd_ptr;
		end
	end
	//two_flop_synchronizer for write
	reg [4:0] wr1_ptr;
	always @(posedge wr_clk or negedge wr_rstn) begin
		if (~wr_rstn) begin 
			rd_sync_wr_ptr <= 0;
			wr1_ptr <= 0;
		end
		else begin
			rd_sync_wr_ptr <= wr1_ptr;
			wr1_ptr <= wr_ptr;
		end
	end
endmodule
