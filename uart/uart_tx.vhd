-- uart tx module

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all; -- used for log2 and ceiling functions for calculating widths

entity uart_tx is
	port(
		i_clk: in std_logic;
		i_rst: in std_logic;

		i_val: in std_logic;
		o_rdy:out std_logic;
		i_dat: in std_logic_vector; --data to transmit, typically 8 width, set to 9 if you want to tx parity

		o_tx : in std_logic;
		i_num_clks: in std_logic_vector --number of clocks, "i_clk", per baud period
	);
end uart_tx;


architecture arch of uart_tx is 
	type t_state is (ST_IDLE, ST_ACTIVE);
	signal     state: t_state;	
	signal nxt_state: t_state;	

	signal cnt_period : unsigned( i_num_clks'length-1 downto 0);
	signal cnt_bits : unsigned(3 downto 0);
	signal cnt_period_tc : std_logic;

	constant CNT_BITS_MAX: unsigned( cnt_bits'range) := to_unsigned( i_dat'length+1, cnt_bits'length);

	signal sr: std_logic_vector( i_dat'range);
begin

	-- ----------------------------
	-- FSM LOGIC
	-- ----------------------------
	process(i_clk) begin
		if rising_edge(i_clk) then
			if i_rst = '1' then
				state <= ST_IDLE;			
			else
				state <= nxt_state;
			end if;
		end if;
	end process;

	-- FSM combinatorial logic
	process(all) begin
		-- default else case
		nxt_state <= state;

		case( state) 
			when ST_IDLE => 
				if i_val = '1' then
					nxt_state <= ST_ACTIVE;
				end if;

			when ST_ACTIVE => 
				if last_bit_done = '1' then
					nxt_state <= ST_IDLE;
				end if;

			when others =>			
				nxt_state <= ST_IDLE;
				
		end case;
	end process;

	-- FSM output  logic
	process(all) begin
		case( state) 
			when ST_IDLE => 
				o_rdy <= '1';

			when ST_ACTIVE => 
				o_rdy <= '0';

			when others =>			
				o_rdy <= '0';
				
		end case;
	end process;
		
	-- ----------------------------
	-- baud period
	-- ----------------------------
	process(i_clk) begin
		if rising_edge(i_clk) then
			if o_rdy = '1' then
				cnt_period <= i_num_clks;
			else
				if cnt_period_tc then
					cnt_period <= i_num_clks;
				else
					cnt_period <= cnt_period - 1;
				end if;
			end if;
		end if;
	end process;

	cnt_period_tc <= cnt_period = CNT_PERIOD_ZERO;


	-- idle  start  b0   b1         b7    P    idle
	-- _____       _____         _       _____ _____
	--	\_____/     \__   //  \_____/
	-- bit:   0   |  1  | 2       |  8  |  9  

	-- ----------------------------
	-- shift register logic 
	-- ----------------------------
	process(i_clk) begin
		if rising_edge(i_clk) then
			if i_val = '1' and o_rdy = '1' then
				sr <= '0' & i_dat & '1' ;
				cnt_bit <= (others => '0');
				last_bit <= '0';
			elsif cnt_period_tc = '1' then
				sr <= sr( sr'length-2 downto 0) & '1';
				--if cnt_bit = (i_dat'length+1)
				if cnt_bit = CNT_BITS_MAX then
					last_bit <= '1';
				else
					cnt_bit <= cnt_bit + 1;
				end if;
			end if;

		end if;
	end process;

	o_tx <= sr( sr'length-1);

end arch;			

