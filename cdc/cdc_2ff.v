module cdc_2ff #(
	parameter WIDTH = 32,
	parameter [WIDTH-1:0] INIT_VALUE = {WIDTH{1'b0}}

)(
	input c,
	input r,
	input  [WIDTH-1:0] i,
	output [WIDTH-1:0] o
);

	(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] ff1 = INIT_VALUE;
	(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] ff2 = INIT_VALUE;

	always @(posedge c) begin
		if(r) begin 
			ff1 <= INIT_VALUE;
			ff2 <= INIT_VALUE;
		end else begin
			ff1 <= i;
			ff2 <= ff1;
		end
	end
	
	assign o = ff2;

endmodule

