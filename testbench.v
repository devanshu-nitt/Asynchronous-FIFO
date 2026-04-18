`timescale 1ns/1ps

module async_fifo_tb;
	
	localparam	WIDTH = 8;
	localparam 	FIFO_DEPTH_WIDTH = 5;
	localparam 	FIFO_DEPTH = 2**FIFO_DEPTH_WIDTH;
	localparam	I = $clog2(FIFO_DEPTH_WIDTH);

	reg	rst, wr_clk, rd_clk, read, write;
	reg	[WIDTH-1:0]	write_data;

	wire	[WIDTH-1:0]	read_data;
	wire			full, empty;
	wire	[FIFO_DEPTH_WIDTH-1:0]	data_count_read, data_count_write;

	async_fifo #( .WIDTH(WIDTH), .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)) DUT (
		.rd_clk(rd_clk),
		.wr_clk(wr_clk),
		.rst(rst),
		.read(read),
		.write(write),
		.write_data(write_data),
		.read_data(read_data),
		.full(full),
		.empty(empty),
		.data_count_read(data_count_read),
		.data_count_write(data_count_write)
	);

	initial wr_clk = 0;
	always #10 wr_clk = ~wr_clk;

	initial rd_clk = 0;
	always #19.23 rd_clk = ~rd_clk;

	integer i;

	initial begin
		
		rst = 0;
		read = 0;
		write = 0;
		write_data = 0;

		#50;
		rst = 1;
		
		for(i = 0; i < 50; i=i+1) begin
			@(negedge wr_clk);
			write_data = i;
			write = 1;
		end
		write = 0;
		#200

		for (i = 0; i < 50; i=i+1) begin
			@(negedge rd_clk);
			read = 1;
		end
		read = 0;
		#200

		read = 1;
		for (i = 0; i < 60; i=i+1) begin
			@(negedge wr_clk);
			write = 1;
			write_data = i;
		end
		read = 0;
		write = 0;
		
		#400;
		$stop;
	end	
	
endmodule