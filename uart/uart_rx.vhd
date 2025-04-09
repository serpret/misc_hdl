-- uart rx module

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all; -- used for log2 and ceiling functions for calculating widths

entity uart_rx is
	port(
		i_clk: in std_logic;
		i_rst: in std_logic;
		i_rx : in std_logic;
		i_num_clks: in std_logic_vector; --number of clocks, "i_clk", per baud period
		o_dat: out std_logic_vector(7 downto 0); --data received
		o_val: out std_logic  -- valid bit, high when data on o_dat is valid.
	);
end uart_rx;


architecture arch of uart_rx is 
	signal sample_time : unsigned( i_num_clks-1 downto 0);
		
	type t_state is (ST_IDLE, ST_START, ST_DATA, ST_STOP);
	signal     state: t_state;	
	signal nxt_state: t_state;	

	signal cnt_period : unsigned( WIDTH_CNT_PERIOD-1 downto 0);
	constant CNT_PERIOD_ZERO : unsigned( cnt_period'range) := (others => '0');

	signal cnt_bits : unsigned(3 downto 0);

	--signal sr : std_logic_vector( 8 downto 0);
	signal sr : std_logic_vector( o_dat'length downto 0); 
begin

	
	-- 2 FF sync i_rx just in case it's not already synced 
	process(i_clk) begin
		if rising_edge(i_clk) then
			rx2 <= i_rx;
			rx  <= rx2;
		end if;
	end process;	

	-- FSM sequential logic
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
		--default else case
		nxt_state <= state;

		case( state) 
			when ST_IDLE => 
				if rx = '0' then
					nxt_state <= ST_DATA;
				end if;

			when ST_DATA =>
				if last_bit and cnt_period_tc then
					nxt_state <= ST_STOP;
				end if;

			when ST_STOP
				if cnt_period_tc then
					nxt_state <= ST_IDLE;
				end if;

			when others =>			
				nxt_state <= ST_IDLE;
				
		end case;

	end process;


	-- idle  start  b0   b1         b7    P    idle
	-- _____       _____         _       _____ _____
	--	\_____/     \__   //  \_____/
	-- bit:   0   |  1  | 2       |  8  |  9  


	sample_time <= '0' & i_num_clks( i_num_clks'length-2 downto 1) ;
	
	-- when do we sample?
	process(i_clk) begin
		if rising_edge(i_clk) then

			-- counter for uart period
			if idle = '1' then
				cnt_period <= i_num_clks;
				cnt_period_tc_reg <= '0';
			else
				if cnt_period = CNT_PERIOD_ZERO then
					cnt_period <= i_num_clks;
					cnt_period_tc_reg <= '1';
				else
					cnt_period <= cnt_period - 1;
					cnt_period_tc_reg <= '0';
				end if;
			end if;

			-- when do we sample?
			if cnt_period = sample_time then
				sample_now <= '1';
			else
				sample_now <= '0';
			end if;
		
			-- keep count of bits shifted in
			if idle = '1' then
				cnt_bits <= (others => '0');
			if cnt_period_tc_reg = '1' then
				if cnt_bits /= 4x"9"; then	
					cnt_bits <= cnt_bits + 1;
				end if;
			end if;

			-- shift register the receive data
			if sample_now = '1'  then
				sr <= i_rx & sr(sr'length-1 downto 1) ;
			end if; 

			-- final output
			if idle = '1' then
				o_dat <= sr(sr'length-1 downto 1);
			end if;

		end if;
	end process;

end arch;			

