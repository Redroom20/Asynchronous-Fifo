module async_fifo(rd_clk, wr_clk, rst, rd_en, wr_en, rdata, wdata, valid, empty, full, overflow,underflow);

parameter data_width = 8;

input rd_clk;
input wr_clk;
input rst;
input rd_en;
input wr_en;
input [data_width-1 : 0] wdata;

output reg [data_width-1 : 0] rdata;
output full;
output empty;
output reg valid;
output reg overflow;
output reg underflow;

parameter fifo_depth = 16;
//parameter data_width = 8;
parameter address_size = 5;

reg [address_size-1:0] wr_ptr;
reg [address_size-1:0] rd_ptr;

wire [address_size-1:0] wr_ptr_gray;
wire [address_size-1:0] rd_ptr_gray;

reg  [address_size-1:0] wr_ptr_gray_s1;
reg  [address_size-1:0] wr_ptr_gray_s2;
reg  [address_size-1:0] rd_ptr_gray_s1;
reg  [address_size-1:0] rd_ptr_gray_s2;

//declaring 2d array
reg [data_width-1:0] mem [fifo_depth-1:0];

//writing data into fifo
always @ (posedge wr_clk) begin
  if (rst) wr_ptr<=0;
  else begin 
    if (wr_en && !full) begin
	   wr_ptr <= wr_ptr + 1;
		mem[wr_ptr] <= wdata;
    end
  end
end

//reading data from fifo
always @ (posedge rd_clk) begin
  if (rst) rd_ptr<=0;
  else begin 
    if (rd_en && !empty) begin
	   rd_ptr <= rd_ptr + 1;
		rdata <= mem[rd_ptr];
    end
  end
end

//wr_ptr,rd_ptr binary to gray
assign wr_ptr_gray = wr_ptr ^ (wr_ptr>>1) ;
assign rd_ptr_gray = rd_ptr ^ (rd_ptr>>1) ;

//2ff synchronizer for wr_ptr wrt rd_clk
always @ (posedge rd_clk) begin
   if (rst) begin
	   wr_ptr_gray_s1 <= 0;
		wr_ptr_gray_s2 <= 0 ;
	end
	else begin
	   wr_ptr_gray_s1 <= wr_ptr_gray;
		wr_ptr_gray_s2 <= wr_ptr_gray_s1 ;
	end
end	

//2ff synchronizer for rd_ptr wrt wr_clk
always @ (posedge wr_clk) begin
   if (rst) begin
	   rd_ptr_gray_s1 <= 0;
		rd_ptr_gray_s2 <= 0 ;
	end
	else begin
	   rd_ptr_gray_s1 <= rd_ptr_gray;
		rd_ptr_gray_s2 <= rd_ptr_gray_s1 ;
	end
end	

//empty and full condition
assign empty = (rd_ptr_gray == wr_ptr_gray_s2);
assign full = (wr_ptr_gray[address_size-1] != rd_ptr_gray_s2[address_size-1])
              && (wr_ptr_gray[address_size-2] != rd_ptr_gray_s2[address_size-2])
				  && (wr_ptr_gray[address_size-3:0] == rd_ptr_gray_s2[address_size-3:0]);

//overflow
always @ (posedge wr_clk) 
    overflow = full && wr_en;

//underflow
always @ (posedge rd_clk) begin
    underflow <= empty && rd_en;
	 valid <= (rd_en && !empty);
end

endmodule
