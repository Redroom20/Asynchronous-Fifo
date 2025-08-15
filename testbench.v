//module tb;
//
//parameter data_width = 8;
//
//reg rd_clk;
//reg wr_clk;
//reg rst;
//reg rd_en;
//reg wr_en;
//reg [data_width-1 : 0] wdata;
//
//wire  [data_width-1 : 0] rdata;
//wire full;
//wire empty;
//wire valid;
//wire overflow;
//wire underflow;
//
//integer k;
//
////parameter fifo_depth = 8;
////parameter data_width = 8;
//
//async_fifo a1(rd_clk, wr_clk, rst, rd_en, wr_en, rdata, wdata, valid, empty, full, overflow,underflow);
//
//initial begin
//rd_clk=0;
//wr_clk=0;
//rst=0;
//
//#20 rst =1;
//#10 rst =0;
//#500 $finish;
//end
//
//always #5 wr_clk=~wr_clk;
//always #7 rd_clk=~rd_clk;
//
//initial begin
// for (k=0; k<12;k=k+1) begin
//    wdata = k;
//	 #10 wr_en=1;
// end
//    wr_en=0;
//end
//
//initial begin 
//  rd_en=0;
//  #150 rd_en=1;
//end 
//
//endmodule
//
//
//
//
//
//
//
//
//
module tb;

  parameter data_width = 8;
  parameter fifo_depth = 16;
  parameter address_size = 5;

  reg rd_clk;
  reg wr_clk;
  reg rst;
  reg rd_en;
  reg wr_en;
  reg [data_width-1 : 0] wdata;
  
  wire [data_width-1 : 0] rdata;
  wire full;
  wire empty;
  wire valid;
  wire overflow;
  wire underflow;

  // Instantiate the async_fifo module
  async_fifo #(data_width) fifo (
    .rd_clk(rd_clk),
    .wr_clk(wr_clk),
    .rst(rst),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .wdata(wdata),
    .rdata(rdata),
    .full(full),
    .empty(empty),
    .valid(valid),
    .overflow(overflow),
    .underflow(underflow)
  );

  // Clock generation for write clock
  always #5 wr_clk = ~wr_clk;

  // Clock generation for read clock
  always #7 rd_clk = ~rd_clk;

  initial begin
    // Initialize signals
    rd_clk = 0;
    wr_clk = 0;
    rst = 0;
    rd_en = 0;
    wr_en = 0;
    wdata = 0;

    // Reset the FIFO
    #10 rst = 1;
    #15 rst = 0;

    // Write data to the FIFO
    #10;
    wr_en = 1;
    wdata = 8'hA5;
    #10;
    wdata = 8'h3C;
    #10;
    wr_en = 0;

    // Read data from the FIFO
    #20;
    rd_en = 1;
    #20;
    rd_en = 0;

    // Test overflow condition
    #30;
    wr_en = 1;
    wdata = 8'hFF;
    repeat (fifo_depth) begin
      #10;
      wdata = wdata + 1;
    end
    wr_en = 0;

    // Test underflow condition
    #50;
    rd_en = 1;
    repeat (fifo_depth + 2) begin
      #10;
    end
    rd_en = 0;

    // Finish the simulation
    #100;
    $finish;
  end


endmodule
