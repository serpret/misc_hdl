module cdc_2ff #(
	parameter WIDTH = 32,
	parameter [WIDTH-1:0] INIT_VALUE = {WIDTH{1'b0}}

)(
	input c,
	input  [WIDTH-1:0] i,
	output [WIDTH-1:0] o
);

	(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] ff1 = INIT_VALUE;
	(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] ff2 = INIT_VALUE;

	always @(posedge c) begin
		ff1 <= i;
		ff2 <= ff1;
	end
	
	assign o = ff2;

endmodule

