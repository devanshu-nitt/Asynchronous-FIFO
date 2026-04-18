module async_fifo #(	parameter WIDTH = 8,
			parameter FIFO_DEPTH_WIDTH = 11,
			parameter FIFO_DEPTH = 2**FIFO_DEPTH_WIDTH,
			parameter I = $clog2(FIFO_DEPTH_WIDTH))(
	
	input wire			rst,
	input wire			wr_clk, rd_clk,
	input wire			read, write,
	input wire	[WIDTH-1:0]	write_data, // input from write clock domain
	
	output wire	[WIDTH-1:0]	read_data, // output to read clock domain // declared as wire because output from dual port ram is combinational.
	output reg			full, // synch to write clock
 	output reg			empty, // synch to read clock
	output reg	[FIFO_DEPTH_WIDTH-1:0]	data_count_read, data_count_write
);
	//Variable Declartion for CDC.
	reg	[FIFO_DEPTH_WIDTH:0]	wr_ptr_sync, wr_grey_sync, rd_ptr_sync, rd_grey_sync, rd_grey_sync_temp, wr_grey_sync_temp;

	initial begin
		full = 0;
		empty = 1;
	end

// Write Clock domain.
	reg	[FIFO_DEPTH_WIDTH:0]	wr_ptr_q = 0;
	reg	[I-1:0]			i;

	wire	[FIFO_DEPTH_WIDTH:0]	wr_grey, wr_grey_nxt;
	wire				we;

	assign wr_grey = (wr_ptr_q)^(wr_ptr_q >> 1);
	assign wr_grey_nxt = (wr_ptr_q + 1'b1)^((wr_ptr_q + 1'b1) >> 1);
	
	assign we = write && !full;

	always @(posedge wr_clk, negedge rst) begin
		if(!rst) begin
			wr_ptr_q <=0;
			full <= 0;
		end
		else begin
			if(write && !full) begin
				wr_ptr_q <= wr_ptr_q + 1'b1;
				full <= wr_grey_nxt == { ~rd_grey_sync[FIFO_DEPTH_WIDTH : FIFO_DEPTH_WIDTH -1], rd_grey_sync[FIFO_DEPTH_WIDTH -2 : 0]};
			end
			else begin 
				full <= wr_grey == { ~rd_grey_sync[FIFO_DEPTH_WIDTH : FIFO_DEPTH_WIDTH -1], rd_grey_sync[FIFO_DEPTH_WIDTH -2 : 0]};
			end
			for ( i=0; i <= FIFO_DEPTH_WIDTH; i = i+1) begin
				rd_ptr_sync[i] = ^(rd_grey_sync >> i);
			end
			data_count_write <= (wr_ptr_q >= rd_ptr_sync) ?  (wr_ptr_q - rd_ptr_sync) : (FIFO_DEPTH - rd_ptr_sync + wr_ptr_q);
		end
	end

// Read Clock Domain.
	reg	[FIFO_DEPTH_WIDTH:0]	rd_ptr_q = 0;
	reg	[I-1:0]			j;
	
	wire	[FIFO_DEPTH_WIDTH:0]	rd_grey, rd_grey_nxt;
	wire	[FIFO_DEPTH_WIDTH:0]	rd_ptr_d;
	
	assign	rd_ptr_d = (read && !empty)? rd_ptr_q + 1'b1 : rd_ptr_q;
	
	assign rd_grey = (rd_ptr_q)^(rd_ptr_q >> 1);
	assign rd_grey_nxt = (rd_ptr_q + 1'b1)^((rd_ptr_q + 1'b1) >> 1); 

	always @(posedge rd_clk, negedge rst) begin
		if(!rst) begin
			rd_ptr_q <= 0;
			empty <= 1;
		end
		else begin
			rd_ptr_q <= rd_ptr_d;
			if(read && !empty) begin
				
				empty <= wr_grey_sync == rd_grey_nxt;
			end
			else begin
				empty <= wr_grey_sync == rd_grey;
			end
			for ( j=0; j <= FIFO_DEPTH_WIDTH; j = j+1) begin
				wr_ptr_sync[j] = ^(wr_grey_sync >> j);
			end
			data_count_read <= (wr_ptr_sync >= rd_ptr_q) ?  (wr_ptr_sync - rd_ptr_q) : (FIFO_DEPTH - rd_ptr_q + wr_ptr_sync);
		end
	end

// Clock Domain Crossing.
	// Have to Check first whether it's legal variable declaration.

	always @(posedge wr_clk) begin
		rd_grey_sync_temp <= rd_grey;
		rd_grey_sync <= rd_grey_sync_temp;
	end
	
	always @(posedge rd_clk) begin
		wr_grey_sync_temp <= wr_grey;
		wr_grey_sync <= wr_grey_sync_temp;
	end

	dual_port_ram #( .WIDTH(WIDTH), .ADDR(FIFO_DEPTH_WIDTH))	RAM	(
		.rd_clk(rd_clk), .wr_clk(wr_clk), .write_data(write_data), .read_data(read_data), .read_addr(rd_ptr_d[FIFO_DEPTH_WIDTH-1:0]), .write_addr(wr_ptr_q[FIFO_DEPTH_WIDTH-1:0]), .write(we) // Using rd_ptr_d as it is ahead of rd_ptr_q, to compensate for 1 cycle delay in read operation.
	);
endmodule
	
