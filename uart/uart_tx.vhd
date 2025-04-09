-- uart tx module

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all; -- used for log2 and ceiling functions for calculating widths

entity uart_rx is
	port(
		i_clk: in std_logic;
		i_rst: in std_logic;

		i_val: in std_logic;
		o_rdy:out std_logic;
		i_dat: in std_logic_vector;

		o_tx : in std_logic;
		i_num_clks: in std_logic_vector --number of clocks, "i_clk", per baud period
	);
end uart_rx;


architecture arch of uart_rx is 
	type t_state is (ST_IDLE, ST_ACTIVE);
	signal     state: t_state;	
	signal nxt_state: t_state;	

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
	-- shift register logic 
	-- ----------------------------
	process(i_clk) begin
		if rising_edge(i_clk) then
			if i_val = '1' and o_rdy = '1' then
				sr <= '0' & i_dat & '1' ;
			elsif tc_cnt_period = '1' then
				sr <= sr( sr'length-2 downto 0) & '1';
			end if;
		end if;
	end process;

	o_tx <= sr( sr'length-1);

end arch;			

