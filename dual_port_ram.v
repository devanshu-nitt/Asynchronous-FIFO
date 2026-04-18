module dual_port_ram #(	parameter WIDTH = 8,
			parameter ADDR = 11,
			parameter DEPTH = 2**ADDR)(
	
	input wire			wr_clk, rd_clk,
	input wire	[WIDTH-1:0]	write_data,
	input wire	[ADDR-1:0]	read_addr, write_addr,
	input wire			write,
	
	output wire	[WIDTH-1:0]	read_data
);
	reg	[ADDR-1:0]	read_addr_temp;
	
	reg	[WIDTH-1:0]	ram	[DEPTH-1:0];

	always @(posedge wr_clk) begin
		if(write) begin
			ram[write_addr] <= write_data;
		end
	end
	
	always @(posedge rd_clk) begin
		read_addr_temp <= read_addr;
		
	end
	assign read_data = ram[read_addr_temp]; // Address is latched and then data is read combinationally to see data at next clock window to accout for clock-to-Q delay.
endmodule