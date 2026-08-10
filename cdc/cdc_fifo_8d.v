// Copyright 2026 sergy pretetsky
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files 
// (the “Software”), to deal in the Software without restriction, 
// including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, 
// and to permit persons to whom the Software is furnished to do so.
// 
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, 
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// 8 deep asynchronous fifo
// (actually its 8-1, 7 deep fifo, false advertising i guess)
// resets are synchronous, can can be tied 0.  
// On FPGA power-up it should be empty, in all other cases either
// use the reset or be ready to pop all fo the garbage data out of the fifo

module cdc_fifo_8d #(
	parameter WIDTH = 32
)(
	input              s_clk,
	input              s_rst,
	input              s_val,
	output             s_rdy,
	input  [WIDTH-1:0] s_dat,
	input              m_clk,
	input              m_rst,
	output             m_val,
	input              m_rdy,
	output [WIDTH-1:0] m_dat 
);

	function [2:0] graycode_next;
		input [2:0] current;
		begin
			case( current)
				3'b000: graycode_next = 3'b001; 
				3'b001: graycode_next = 3'b011;
				3'b011: graycode_next = 3'b010;
				3'b010: graycode_next = 3'b110;
				3'b110: graycode_next = 3'b111;
				3'b111: graycode_next = 3'b101;
				3'b101: graycode_next = 3'b100;
				3'b100: graycode_next = 3'b000;

				default: graycode_next = 3'b000 ;
			endcase
		end
	endfunction

	// prefix explanation:
	//      mcd_ -> m clock domain
	reg [2:0] mcd_idx;
	reg [2:0] scd_idx;

	wire [2:0] mcd_s_idx;
	wire [2:0] scd_m_idx;
	
	//clock domain crossing of indices 
	cdc_2ff #(3) u_sync_idx_s2m (.r(m_rst),  .c(m_clk), .i( scd_idx), .o( mcd_s_idx));
	cdc_2ff #(3) u_sync_idx_m2s (.r(s_rst),  .c(s_clk), .i( mcd_idx), .o( scd_m_idx));

	//handle s side
	assign s_rdy = graycode_next( scd_idx) != scd_m_idx;
	always @(posedge s_clk) begin
		if( s_rst) begin
			scd_idx <= 3'b000;
		end else begin
			if ( s_rdy & s_val) begin
				scd_idx <= graycode_next( scd_idx);
			end
		end
	end 

	//handle m side
	assign m_val = mcd_idx != mcd_s_idx;
	always @(posedge m_clk) begin
		if( m_rst) begin
			mcd_idx <= 3'b000;
		end else begin
			if ( m_rdy & m_val) begin
				mcd_idx <= graycode_next( mcd_idx);
			end
		end
	end 

	//handle 8 registers where data is stored
	reg [WIDTH-1:0] register [0:7];

	//first handle writes:
	always @(posedge s_clk) begin
		if (s_val & s_rdy) begin
			case( scd_idx)

				3'b000: register[0] <= s_dat; 
				3'b001: register[1] <= s_dat;
				3'b011: register[3] <= s_dat;
				3'b010: register[2] <= s_dat;
				3'b110: register[6] <= s_dat;
				3'b111: register[7] <= s_dat;
				3'b101: register[5] <= s_dat;
				3'b100: register[4] <= s_dat;

				//default: register[0]
			endcase
		end
	end


	//now handle reads:
	reg [WIDTH-1:0] m_dat_reg;
	always @(*) begin
		case( mcd_idx)

			3'b000: m_dat_reg <=  register[0] ; 
			3'b001: m_dat_reg <=  register[1] ;
			3'b011: m_dat_reg <=  register[3] ;
			3'b010: m_dat_reg <=  register[2] ;
			3'b110: m_dat_reg <=  register[6] ;
			3'b111: m_dat_reg <=  register[7] ;
			3'b101: m_dat_reg <=  register[5] ;
			3'b100: m_dat_reg <=  register[4] ;

			default: m_dat_reg <= register[0] ;
		endcase
	end
	assign m_dat = m_dat_reg;

endmodule

