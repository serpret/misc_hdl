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
always #13 m_clk = !m_clk;

task push( input [WIDTH-1:0] dat);
begin
	s_dat <= dat;
	s_val <= 1'b1;
	repeat(1) @(posedge s_clk);
	while (s_rdy !== 1'b1) begin
		repeat(1) @(posedge s_clk);
	end
	s_val <= 1'b0;
	s_dat <= {WIDTH{1'bX}};
end
endtask

task pop( input [WIDTH-1:0] dat_expct);
begin
	m_rdy <= 1'b1;
	repeat(1)@(posedge m_clk);
	while( m_val !== 1'b1) begin
		repeat(1) @(posedge m_clk);
	end
	m_rdy <= 1'b0; 
	if (m_dat !== dat_expct) begin
		$display("pop expect failure");
	end
end
endtask

integer i;
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

	//$display("stage1");

	repeat(1) @(posedge s_clk);
	s_rst <= 1'b0;
	//$display("stage2");
	repeat(4) @(posedge m_clk);
	m_rst <= 1'b0;

	repeat(1) @(posedge s_clk);
	//#100;
	push(16'h0123);
	push(16'h4567);
	pop(16'h0123);
	pop(16'h4567);
	repeat(4) @(posedge s_clk);
	push(16'h0123);
	push(16'h4567);
	push(16'h89ab);
	push(16'hcdef);
	push(16'h0123);
	push(16'h4567);
	push(16'h89ab);
	repeat(4) @(posedge s_clk);
	pop(16'h0123);
	pop(16'h4567);
	pop(16'h89ab);
	pop(16'hcdef);
	pop(16'h0123);
	pop(16'h4567);
	pop(16'h89ab);

	//full throughput test
	m_rdy <= 1'b1;
	
	for (i=0; i<64; i = i+1 ) begin
		push( i);
	end
	while (m_val === 1'b1) begin
		repeat(1) @(posedge m_clk);
	end

	repeat(4) @(posedge s_clk);
	$finish;

end
endmodule

