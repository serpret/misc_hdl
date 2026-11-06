module dpram #(
	parameter WIDTH_DATA = 32,
	parameter WIDTH_ADDR = 8,
	parameter DEPTH = 256
)(
	input i_clk,
	input i_we,
	input [WIDTH_ADDR-1:0] i_wr_addr,
	input [WIDTH_ADDR-1:0] i_rd_addr,
	input [WIDTH_DATA-1:0] i_wr_data,
	output reg [WIDTH_DATA-1:0] o_rd_data
);
	
	reg [WIDTH_DATA-1:0] mem [DEPTH-1:0];

	always @(posedge i_clk) begin
		if(i_we) 
			mem[i_wr_addr] <= i_wr_data;
	end

	always @(posedge i_clk) begin
		o_rd_data <= mem[i_rd_addr];
	end

endmodule

