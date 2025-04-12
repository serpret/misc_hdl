-- uart rx module

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all; -- used for log2 and ceiling functions for calculating widths

entity uart_rx is
	port(
		i_clk: in std_logic;
		i_rst: in std_logic;
		i_rx : in std_logic;
		i_num_clks: in std_logic_vector; --number of clocks, "i_clk", per baud period
		o_dat: out std_logic_vector; --data received, typically 8 width, set to 9 if you expect to rx parity
		o_val: out std_logic  -- valid bit, high when data on o_dat is valid.
	);
end uart_rx;


architecture arch of uart_rx is 
	--constant WIDTH_CNT_PERIOD : positive := positive( ceil(log2( i_num_clks'length	
	signal sample_time : unsigned( i_num_clks'length-1 downto 0);
	signal sample_now : std_logic;
		
	type t_state is (ST_IDLE,  ST_DATA, ST_STOP);
	signal     state: t_state;	
	signal nxt_state: t_state;	
	signal idle: std_logic;
	
	signal rx2: std_logic;
	signal rx : std_logic;
	signal last_bit: std_logic;

	signal cnt_period : unsigned( i_num_clks'length-1 downto 0);
	constant CNT_PERIOD_ZERO : unsigned( cnt_period'range) := (others => '0');
	signal cnt_period_tc : std_logic;

	signal cnt_bits : unsigned(3 downto 0);
	constant CNT_BITS_MAX: unsigned( cnt_bits'range) := to_unsigned( o_dat'length+1, cnt_bits'length);

	--signal sr : std_logic_vector( 8 downto 0);
	signal sr : std_logic_vector( o_dat'length+1 downto 0); 
begin

	
	-- 2 FF sync i_rx just in case it's not already synced 
	-- (i_rx can be directly assigned to rx if i_rx is already synced to i_clk) 
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

		case( state) is
			when ST_IDLE => 
				if rx = '0' then
					nxt_state <= ST_DATA;
				end if;

			when ST_DATA =>
				if last_bit = '1' and cnt_period_tc = '1' then
					--nxt_state <= ST_STOP;
					nxt_state <= ST_IDLE;
				end if;

			--when ST_STOP =>
			--	if cnt_period_tc = '1' then
			--		nxt_state <= ST_IDLE;
			--	end if;

			when others =>			
				nxt_state <= ST_IDLE;
				
		end case;

	end process;

	--FSM outputs
	process(all) begin
		case( state) is
			when ST_IDLE =>
				idle <= '1';

			--when ST_DATA => 
			--when ST_STOP =>
			when others =>
				idle <= '0';
		end case;

	end process;


	-- idle  start  b0   b1         b7    P    idle
	-- _____       _____         _       _____ _____
	--	\_____/     \__   //  \_____/
	-- bit:   0   |  1  | 2       |  8  |  9  


	sample_time <= unsigned( '0' & i_num_clks( i_num_clks'length-1 downto 1) ) ;
		
	cnt_period_tc <= '1' when cnt_period = CNT_PERIOD_ZERO else '0';
	
	-- when do we sample?
	process(i_clk) begin
		if rising_edge(i_clk) then

			-- counter for uart period
			if idle = '1' then
				cnt_period <= unsigned(i_num_clks);
			else
				if cnt_period_tc then
					cnt_period <= unsigned(i_num_clks);
				else
					cnt_period <= cnt_period - 1;
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
				last_bit <= '0';
			elsif cnt_period_tc = '1' then
				if cnt_bits /= CNT_BITS_MAX then	
					cnt_bits <= cnt_bits + 1;
				else
					last_bit <= '1';
				end if;
			end if;

			-- shift register the receive data
			if sample_now = '1'  then
				sr <= i_rx & sr(sr'length-1 downto 1) ;
			end if; 

			-- final output
			if idle = '1' then
				o_dat <= sr(sr'length-3 downto 0);
			end if;

		end if;
	end process;

	o_val <= idle;

end arch;			

