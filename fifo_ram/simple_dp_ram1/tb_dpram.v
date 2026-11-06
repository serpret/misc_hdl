module tb();

	reg         i_clk    ;  
	reg         i_we     ;  
	reg  [3:0]  i_wr_addr;
	reg  [3:0]  i_rd_addr;
	reg  [7:0] i_wr_data;
	wire [7:0] o_rd_data; 

	always 
		#5 i_clk <= ~i_clk;
	

	dpram #(
		.WIDTH_DATA(8),
		.WIDTH_ADDR(4),
		.DEPTH(16)
	) uut (
		.i_clk(i_clk),          //input 
		.i_we(i_we),           //input 
		.i_wr_addr(i_wr_addr),      //input [WIDTH_ADDR-1:0] 
		.i_rd_addr(i_rd_addr),      //input [WIDTH_ADDR-1:0] 
		.i_wr_data(i_wr_data),      //input [WIDTH_DATA-1:0] 
		.o_rd_data(o_rd_data)       //output [WIDTH_DATA-1:0] 
	);

	integer rd_idx;
	integer wr_idx;
	initial begin
		$dumpfile("sim_dpram.vcd");
		$dumpvars(0, tb);
		i_clk <= 1'b0;
		i_we  <= 1'b0;
		i_rd_addr <= 8'h00;

		i_we <= 1'b1;
		for(rd_idx=0; rd_idx<16; rd_idx=rd_idx+1) begin
			i_rd_addr <= rd_idx;
			for(wr_idx=0; wr_idx<16; wr_idx=wr_idx+1) begin
				i_wr_addr <= wr_idx;
				i_wr_data <= wr_idx+rd_idx+3;
				@(posedge i_clk);
				
			end
		end

		//repeat(1) @(posedge i_clk);
		//i_we <= 1'b1;
		//i_wr_addr <= 4'h0;
		//i_wr_data <= 8'h00;

		//repeat(1) @(posedge i_clk);
		//i_we <= 1'b1;
		//i_wr_addr <= 4'h1;
		//i_wr_data <= 8'hFF;

		//repeat(1) @(posedge i_clk);
		//i_we <= 1'b0;
		//i_rd_addr <= 8'h01;

		//repeat(1) @(posedge i_clk);

		$finish;
		

	end

endmodule
