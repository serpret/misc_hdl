module i2c_slv_single_byte #(
	parameter NUM_CLKS_IDLE_TO  = 16*50, //800 
	parameter NUM_CLKS_T_BUF    = 16*5 , //80
	parameter WIDTH_IDLE_TO     =   10
	
	//parameter EN_2FF_SYNC       =    0,
	//parameter EN_SDA_SCL FILTER =    0,

)(
	input       i_clk  ,
	input       i_rstn ,
	input [6:0] i_addr ,
	input [7:0] i_data ,
	input       i_scl  ,
	input       i_sda  ,
	
	output reg       o_sda ,
	output reg [7:0] o_data
	
);

	wire start;
	wire stop;
	wire idle;
	
	reg [WIDTH_IDLE_TO-1:0] idle_timer;
	
	reg [3:0] bit_cnt;
	reg ack_bit;
	

	
	reg prev_scl;
	wire posedge_scl;
	wire negedge_scl;
	
	reg prev_sda;
	wire posedge_sda;
	wire negedge_sda;
	
	
	//reg [18:0] shift_in_reg;
	reg [7:0] shift_in_reg;

	reg [18:0] shift_out_reg;


	reg addr_match , set_addr_match;
	reg addr_block , clr_addr_block;
	reg willbe_read, set_willbe_read;
	reg capture_data;
	
	reg read_block ;

	

	wire  shift_out_wire;
	
	assign idle = (0 == idle_timer);
	
	assign shift_out_wire = shift_out_reg[18];
	
	assign posedge_scl = ~prev_scl &  i_scl;
	assign negedge_scl =  prev_scl & ~i_scl;
	
	assign posedge_sda = ~prev_sda &  i_sda;
	assign negedge_sda =  prev_sda & ~i_sda;

	assign start = negedge_sda & i_scl;
	assign stop  = posedge_sda & i_scl;
	
	always @(posedge i_clk) begin
		prev_scl <= i_scl;
		prev_sda <= i_sda;
	end

	always @( posedge i_clk) begin
		//if( posedge_scl) shift_in_reg <= { shift_in_reg[17:0], i_sda};
		if( posedge_scl) shift_in_reg <= { shift_in_reg[7:0], i_sda};

	end
	
	
	always @( posedge i_clk) begin
		if     ( idle || start)   shift_out_reg <= { 1'b1, 8'hFF, 1'b0, i_data[7:0], 1'b1};
		else if( negedge_scl  )   shift_out_reg <= { shift_out_reg[17:0], 1'b1};
	end


	//
	always @( posedge i_clk) begin
		if( idle || !addr_match) o_sda <= 1'b1;
		else begin
			case( { ack_bit , read_block} )
				2'b00:   o_sda <= 1'b1;
				2'b01:   o_sda <= shift_out_wire;
				2'b10:   o_sda <= 1'b0;
				2'b11:   o_sda <= shift_out_wire;
				default: o_sda <= 1'b1;
			endcase
		end
	end
	
	
	//keep track of bit count
	// scl      HHHHHH\___/HHH\___/HHH\  ...   HHH\___/HHH\___/HHH\___/HHH\___/HHH\  ...   HHH\___/HHH\___/HHHHHH
	// sda      HH\____/ ADDR6 X ADDR5   ... ADDR0 X Read  x NACK  X DAT7  X DAT6    ... DAT0  X NACK  X______/HHH
	// bit_cnt  XXX 0  X  1    X   2     ...   7   X  8    X  9    X  1    X  2      ...  8    X 9     X  1
	// full cnt     0     1        2           7      8       9       10      11          17     18      19
	always @(posedge i_clk) begin
		//if(                                start  ) bit_cnt <= 0;
		//else if ( negedge_scl && ( 19 != bit_cnt) ) bit_cnt <= bit_cnt + 1'b1;
		
		if(                                start  ) bit_cnt <= 0;
		else if ( negedge_scl  ) begin
			if( 9 != bit_cnt) bit_cnt <= bit_cnt + 1'b1;
			else              bit_cnt <= 1;
		end
	end
	
	
	always @( posedge i_clk) begin
		if( 9 == bit_cnt ) ack_bit <= 1'b1;
		else               ack_bit <= 1'b0;
	end
	
	
	always @(posedge i_clk) begin
		if( start || ~i_scl) idle_timer <= NUM_CLKS_IDLE_TO;
		else if( stop )      idle_timer <= NUM_CLKS_T_BUF;
		else if(!idle )      idle_timer <= idle_timer - 1'b1;
	end
	

	
	always @(posedge i_clk) begin
		set_addr_match  <=  (4'd7 == bit_cnt) && negedge_scl &&  addr_block && ( i_addr == shift_in_reg[6:0] );
		set_willbe_read <=  (4'd8 == bit_cnt) && negedge_scl &&  addr_block &&             shift_in_reg[0]    ;
		clr_addr_block  <=  (4'd9 == bit_cnt) && negedge_scl                                                  ;
		capture_data    <=  (4'd8 == bit_cnt) && negedge_scl && !addr_block && addr_match && !read_block      ;
	end
	
	
	always @(posedge i_clk) begin
		if( idle )                addr_block <= 1;
		else if ( clr_addr_block) addr_block <= 0;
	end
	
	always @(posedge i_clk) begin
		if( idle )               addr_match <= 1'b0;
		else if( set_addr_match) addr_match <= 1'b1;
	end
	
	always @(posedge i_clk) begin
		if( idle )                 willbe_read <= 1'b0;
		else if( set_willbe_read ) willbe_read <= 1'b1;
	end
	
	always @(posedge i_clk) begin
		read_block <= willbe_read && !addr_block;
	end
	
	always @(posedge i_clk) begin
		if(capture_data) o_data <= shift_in_reg[7:0];
	end
	

endmodule