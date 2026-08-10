`timescale 1ns/100ps

module tb;

localparam WIDTH = 16;

reg  s_clk; 
reg  s_rst;
reg  s_val;
wire s_rdy;
reg  [WIDTH-1:0] s_dat;

reg  m_clk; 
reg  m_rst;
wire m_val;
reg  m_rdy;
wire [WIDTH-1:0] m_dat;
	
cdc_fifo_8d #(
	.WIDTH(WIDTH)
) UUT (
	.s_clk(s_clk),  //input              
	.s_rst(s_rst),  //input              
	.s_val(s_val),  //input              
	.s_rdy(s_rdy),  //output             
	.s_dat(s_dat),  //input  [WIDTH-1:0] 
	.m_clk(m_clk),  //input              
	.m_rst(m_rst),  //input              
	.m_val(m_val),  //output             
	.m_rdy(m_rdy),  //input              
	.m_dat(m_dat)   //output [WIDTH-1:0] 
);


always #5 s_clk = !s_clk;
always #6 m_clk = !m_clk;

initial begin
	$dumpfile("sim_cdc_fifo_8d.vcd");
	$dumpvars(0, tb);
	s_clk <= 1'b0; 
	s_rst <= 1'b1;
	
	m_clk <= 1'b0;
	m_rst <= 1'b1;
	s_val <= 1'b0;
	s_dat <= 16'hXXXX;
	m_rdy <= 1'b0;

	$display("stage1");

	//repeat(1) @(posedge s_clk);
	//s_rst <= 1'b0;
	//$display("stage2");
	//repeat(1) @(posedge m_clk);
	//m_rst <= 1'b0;

	//repeat(1) @(posedge s_clk);
	#100;

	$finish;

end
endmodule

