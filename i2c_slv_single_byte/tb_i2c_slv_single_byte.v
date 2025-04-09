`timescale 1ns/100ps


module tb();
	//parameters
	
	localparam NS_TB_GENERAL_TIMEOUT = 100_000_000;
	
	localparam NUM_CLKS_IDLE_TO = 800;
	localparam NUM_CLKS_T_BUF   = 80 ;
	localparam WIDTH_IDLE_TO    = 10 ;
	
	reg            i_clk ;
	reg            i_rstn;
	reg   [6:0]    i_addr;
	reg   [7:0]    i_data;
	reg            i_scl ;
	reg            i_sda ;
	wire           o_sda ;
	wire  [7:0]    o_data;
	
	
	wire scl;
	wire sda;
	
	
	//driver
	reg              drv_start                 ; 
	reg   [31:0]     drv_scl_lo_timing         ; 
	reg   [31:0]     drv_scl_hi_timing         ; 
	reg   [2:0]      drv_num_bytes             ; 
	reg   [2:0]      drv_repeatstart_after_byte; 
	reg   [2:0]      drv_stop_after_byte       ; 
	reg   [8:0]      drv_byte_0                ; 
	reg   [8:0]      drv_byte_1                ; 
	reg   [8:0]      drv_byte_2                ; 
	reg   [8:0]      drv_byte_3                ; 
	reg   [8:0]      drv_byte_4                ; 
	reg   [8:0]      drv_byte_5                ; 
	reg   [8:0]      drv_byte_6                ; 
	
	wire  drv_scl ;
	wire  drv_sda ;
	wire  drv_idle;
	
	//uut monitor signals
	reg rst_latch_uut_sda_low;
	reg      uut_sda_went_low;
	
	reg [18:0] mon_shift_reg;
	
	
	

	
	

	//clock generate
	always #32        i_clk         = ~i_clk;
	
	
	i2c_slv_single_byte #(
		.NUM_CLKS_IDLE_TO  (NUM_CLKS_IDLE_TO),
		.NUM_CLKS_T_BUF    (NUM_CLKS_T_BUF  ),
		.WIDTH_IDLE_TO     (WIDTH_IDLE_TO   )
	
	) uut (
		.i_clk  (i_clk  ),
		.i_rstn (i_rstn ),
		.i_addr (i_addr ),//[6:0]
		.i_data (i_data ),//[7:0]
		.i_scl  (i_scl  ),
		.i_sda  (i_sda  ),
		.o_sda  (o_sda  ),
		.o_data (o_data )//[7:0]
		
	);
	

	driver_msti2c u_driver_cha_mst(
		.i_scl                   ( scl                      ),
		.i_sda                   ( sda                      ),
		.i_start                 (drv_start                 ),  
		.i_scl_lo_timing         (drv_scl_lo_timing         ), //[31:0]
		.i_scl_hi_timing         (drv_scl_hi_timing         ), //[31:0]
		.i_num_bytes             (drv_num_bytes             ), //[2:0] 
		.i_repeatstart_after_byte(drv_repeatstart_after_byte), //[2:0] 
		.i_stop_after_byte       (drv_stop_after_byte       ), //[2:0] 
		.i_byte_0                (drv_byte_0                ), //[8:0] 
		.i_byte_1                (drv_byte_1                ), //[8:0] 
		.i_byte_2                (drv_byte_2                ), //[8:0] 
		.i_byte_3                (drv_byte_3                ), //[8:0] 
		.i_byte_4                (drv_byte_4                ), //[8:0] 
		.i_byte_5                (drv_byte_5                ), //[8:0] 
		.i_byte_6                (drv_byte_6                ), //[8:0] 
	
		.o_scl (drv_scl ),
		.o_sda (drv_sda ),
		.o_idle(drv_idle)
	);
	
	
	assign scl = drv_scl ;
	assign sda = drv_sda & o_sda;

	always @(*) begin
		i_scl = scl;
		i_sda = sda;
	end
	
	
	always @(negedge o_sda, posedge rst_latch_uut_sda_low) begin
		if( rst_latch_uut_sda_low) uut_sda_went_low = 1'b0;
		else if ( ~o_sda )         uut_sda_went_low = 1'b1;
	end
	
	always @(posedge scl) begin
		mon_shift_reg <= {mon_shift_reg[17:0], sda};
	end
		

	integer failed = 0;
	//integer subtest_failed ;
	initial begin
		$timeformat(-6,3, "us", 12);
		init_vars();
		rst_uut();
		
		#100_000;
		
		rst_sda_mon();
		i_addr = 7'h51;
		write_byte( 7'h52, 8'hAC);
		if( 8'hAC === o_data) fail_general( "write wrong address, o_data incorrect", " ");
		if( uut_sda_went_low) fail_general( "write wrong address o_sda fell", " ");

		
		rst_sda_mon();
		read_byte( 7'h52);
		if(uut_sda_went_low) fail_general("read wrong address o_sda fell", " ");
		
		//read_byte( 7'h51);
		write_byte( 7'h51, 8'h53);
		if( 8'h53 !== o_data) fail_general( "write , o_data incorrect", " ");

		i_data = 8'h21;
		read_byte( 7'h51);
		if( {7'h51, 1'b1, 1'b0} !== mon_shift_reg[18:10]) fail_general( "read o_sda shift addr incorrect", " ");
		if( i_data !== mon_shift_reg[9:2])                fail_general( "read o_sda shift data incorrect", " ");
		//read_byte( 7'h53);
		

		if( failed) $display(" ! ! !  TEST FAILED ! ! !");
		else        $display(" Test Passed ");
		$stop();
	
	end


	task init_vars;
		begin
			i_clk = 0;
			i_rstn = 0;
			
			uut.idle_timer = 10;


			i_addr = 7'h00;
			i_data = 8'h00;
			i_scl  = 1'b1;
			i_sda  = 1'b1;
			
			
			rst_latch_uut_sda_low = 1'b0;
			
		end
	endtask
	
	
	
	task rst_uut;
		begin
		
		i_rstn = 0;
		repeat(1) @(posedge i_clk);
		i_rstn = 1;
		repeat(1) @(posedge i_clk);
		
		end
	endtask
	
	task rst_sda_mon;
		begin
			rst_latch_uut_sda_low = 1'b1;
			#1;
			rst_latch_uut_sda_low = 1'b0;
		end
	endtask
	
	
	
	task write_byte;
		input [6:0] addr;
		input [7:0] data;
		begin
		
			//setup master
			drv_scl_lo_timing          = 32'd5000;
			drv_scl_hi_timing          = 32'd4700;
			
			drv_num_bytes             = 3'b010;
			drv_repeatstart_after_byte= 3'b111;
			drv_stop_after_byte       = 3'b001;
			
			drv_byte_0        = {addr, 1'b0, 1'b1};
			drv_byte_1        = {data,       1'b1};
			
			start_mst();
			
			
			wait_all_idle( "write_byte", " ", NS_TB_GENERAL_TIMEOUT);

			#5500;
			

		end
	endtask
	
	
	task read_byte;
		input [6:0] addr;

		begin
		
				
			//setup master
			drv_scl_lo_timing          = 32'd5000;
			drv_scl_hi_timing          = 32'd4700;
			
			drv_num_bytes             = 3'b010;
			drv_repeatstart_after_byte= 3'b111;
			drv_stop_after_byte       = 3'b001;
			
			drv_byte_0        = {addr , 1'b1, 1'b1};
			drv_byte_1        = {8'hFF,       1'b0};
			
			start_mst();
			
			wait_all_idle( "read_byte", " ", NS_TB_GENERAL_TIMEOUT);
			#5500;
			
		end
	endtask
	
	
		
	task start_mst;
		begin
			drv_start = 1;
			#1;
			drv_start = 0;
		end
	endtask
	
	
	
	
	task wait_all_idle;
		input [511:0] str_err;
		input [511:0] str_suberr;
		input realtime timeout_time;
		
		realtime start_time;
		//reg [31:0] i;
		begin
			start_time = $realtime;
			while( (!all_idle(0)) && (time_elapsed( start_time) < timeout_time) ) begin
				
				@(posedge i_clk);
			end
			if( !all_idle(0)) fail_tb_timeout(str_err, str_suberr);
		end
	endtask
	
	
		
	function all_idle;
		input nc;
		begin
			all_idle  = drv_idle && drv_idle && scl && sda ;
		end
	endfunction
	
	
	
	task fail_tb_timeout;
		input [511:0] str_err;
		input [511:0] str_suberr;
		begin
			$display("-------  Failed test  ------", str_err);
			$display("    testbench timeout occured");
			$display("    failure type    : %s", str_lalign(str_err   ) );
			$display("    failure substype: %s", str_lalign(str_suberr) );
			$display("    time            : %t", $realtime);
			failed = 1;
			
			$display("------- Timeout occured waiting for some condition ------");
			$display("------- testbench in unknown state, stop entire test ----");
			$stop();
		end
	endtask
	
	
	task fail_general;
		input [511:0] str_err;
		input [511:0] str_suberr;
		begin
			$display("-------  Failed test  ------");
			$display("    failure type    : %s", str_lalign(str_err   ) );
			$display("    failure substype: %s", str_lalign(str_suberr) );
			$display("    time            : %t", $realtime);
			failed = 1;
		end
	endtask
	
	
	
	function [511:0] str_lalign;
		input [511:0] str;
		begin
			//$display("str_lalign debug str[511 -:8]: %h", str_lalign[511 -:8]);
			str_lalign = str;
			while( str_lalign[ 511 -:8] == 8'h00  ||
			       str_lalign[ 511 -:8] == 8'h10  ||
			       str_lalign[ 511 -:8] === 8'hXX ||
			       str_lalign[ 511 -:8] === 8'hZZ 
			
			) begin
				str_lalign = str_lalign << 8;
			end
		end
	endfunction
	
	
	
	
	function realtime time_elapsed;
		input realtime start;
		begin
			time_elapsed = $realtime - start;
		end
	endfunction
	
	
endmodule








//i2c master.  does not diffentiate between read or write operations
module driver_msti2c(
	input i_scl,
	input i_sda,
	
	//posedge starts transaction
	input i_start,  
	

	//how long scl will stay high and low
	input [31:0] i_scl_lo_timing,
	input [31:0] i_scl_hi_timing,
	
	
	//number of bytes for this transaction (including address, write, and read)
	input [2:0] i_num_bytes, 
	
	//insert repeat start control bit or stop control bit
	//after which byte.  Set to 7 to not insert.
	input [2:0] i_repeatstart_after_byte,
	input [2:0] i_stop_after_byte,
	
	//data bytes
	input [8:0] i_byte_0  , //first block to send
	input [8:0] i_byte_1  ,
	input [8:0] i_byte_2  ,
	input [8:0] i_byte_3  ,
	input [8:0] i_byte_4  ,
	input [8:0] i_byte_5  ,
	input [8:0] i_byte_6  , //last block to send
	
	
	output reg o_scl,
	output reg o_sda,
	
	output reg o_idle


);
	localparam NUM_DAT_BITS = 7*9;
	reg [NUM_DAT_BITS-1:0] all_bytes;
	reg [3:0] bit_cnt;
	reg [3:0] byte_cnt;
	
	wire       nxt_bit_is_ctrl;
	wire       cur_bit_is_ctrl;
	
	wire final_byte;
	wire stop_byte;
	

	assign       final_byte = (i_num_bytes               === (byte_cnt+1'b1  )    );
	assign        stop_byte = (i_stop_after_byte         ===  byte_cnt            );
	assign repeatstart_byte = (i_repeatstart_after_byte  ===  byte_cnt            );
	
	assign cur_bit_is_last           = (4'h9 == bit_cnt);
	//assign cur_bit_is_almost_last    = (4'h7 === bit_cnt);
	
	assign nxt_bit_is_ctrl = (stop_byte || repeatstart_byte) && cur_bit_is_last;
	assign cur_bit_is_ctrl = (stop_byte || repeatstart_byte) && ( bit_cnt == 4'ha);


	initial begin
		o_idle = 1'b1;
		o_scl = 1'b1;
		o_sda = 1'b1;
	end
	
	always @(posedge i_start) begin
		bit_cnt  = 0;
		byte_cnt = 0;
		all_bytes = { 
			i_byte_0  ,
			i_byte_1  ,
			i_byte_2  ,
			i_byte_3  ,
			i_byte_4  ,
			i_byte_5  ,
			i_byte_6  
		};
		o_idle = 0;
		o_scl = 1'b1;
		o_sda = 1'b0;
		
		o_scl <= #i_scl_hi_timing 1'b0;
	end
	
	//generate o_idle
	always @(posedge i_scl) begin
		if( final_byte && cur_bit_is_last) o_idle <= #i_scl_hi_timing 1'b1;
	end
	
	//generate o_scl next rising edge
	always @(negedge i_scl) begin
		o_scl <= #i_scl_lo_timing 1'b1;
	end
	
	//generate o_scl next falling edge
	always @(posedge i_scl) begin
		if( final_byte && cur_bit_is_last) o_scl = 1'b1; //do nothing
		else begin
			if(!o_idle) begin
				if( nxt_bit_is_ctrl) o_scl <= #(2*i_scl_hi_timing) 1'b0;
				else                 o_scl <= #(  i_scl_hi_timing) 1'b0; //normal data bit
			end
		end
	end
	
	//bit_cnt  byte_cnt
	always @(posedge i_scl) begin
		//bit_cnt <= ( cur_bit_is_last ) ? 0 : bit_cnt + 1'b1;
		bit_cnt <= (cur_bit_is_last && !nxt_bit_is_ctrl) || cur_bit_is_ctrl ?               1 : bit_cnt + 1'b1;
		byte_cnt<= (cur_bit_is_last && !nxt_bit_is_ctrl) || cur_bit_is_ctrl ? byte_cnt + 1'b1 :       byte_cnt;
	end
	
	//o_sda  logic 
	always @(i_scl) begin
	
		if( !o_idle) begin
			//posedge i_scl
			if( i_scl) begin
				if( nxt_bit_is_ctrl) begin
					o_sda <= #(i_scl_hi_timing) ( stop_byte ? 1'b1 : 1'b0 );
				end
			end
			//negedge i_scl
			else begin 
				if( nxt_bit_is_ctrl) begin
					o_sda <=  (stop_byte ? 1'b0 : 1'b1);
				end
				else begin
					o_sda <=  all_bytes[NUM_DAT_BITS-1];
					all_bytes = (all_bytes << 1);
				end
			end
		end
	end
	

endmodule




