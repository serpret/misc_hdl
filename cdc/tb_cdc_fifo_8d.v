module tb;

localparam WIDTH = 16;

reg  s_clk; 
reg  s_rst;
reg  s_val;
wire s_rdy;
reg  [WIDTH-1:0] s_dat;

reg  m_clk
reg  m_rst
wire m_val
wire m_rdy
m_dat
	
cdc_fifo_8d #(
	.WIDTH(WIDTH)
) UUT (
	.s_clk(s_clk),  //input              
	.s_rst(s_rst),  //input              
	.s_val(s_val),  //input              
	.s_rdy(s_rdy),  //output             
	.s_dat(s_dat)   //input  [WIDTH-1:0] 
	.m_clk(m_clk),  //input              
	.m_rst(m_rst),  //input              
	.m_val(m_val),  //output             
	.m_rdy(m_rdy),  //input              
	.m_dat(m_dat)   //output [WIDTH-1:0] 
);


always #5 s_clk <= 
