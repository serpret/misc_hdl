
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is end tb;



architecture arch of tb is

	signal i_tx_clk     : std_logic;
	signal i_tx_rst     : std_logic;
	signal i_tx_val     : std_logic;
	signal o_tx_rdy     : std_logic;
	signal i_tx_dat     : std_logic_vector(7 downto 0);
	signal wire         : std_logic;
	signal i_tx_num_clks: std_logic_vector(5 downto 0);


	component uart_tx is
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

	component uart_rx is
		port(
			i_clk: in std_logic;
			i_rst: in std_logic;
			i_rx : in std_logic;
			i_num_clks: in std_logic_vector; --number of clocks, "i_clk", per baud period
			o_dat: out std_logic_vector; --data received, typically 8 width, set to 9 if you expect to rx parity
			o_val: out std_logic  -- valid bit, high when data on o_dat is valid.
		);
	end uart_rx;
	
begin


	UUT_TX: uart_tx
		port map(
			i_clk      =>i_tx_clk     , -- in std_logic;
			i_rst      =>i_tx_rst     , -- in std_logic;
			i_val      =>i_tx_val     , -- in std_logic;
			o_rdy      =>o_tx_rdy     , --out std_logic;
			i_dat      =>i_tx_dat     , -- in std_logic_vector; --data to transmit, typically 8 width, set to 9 if you want to tx parity
			o_tx       =>wire         , -- in std_logic;
			i_num_clks =>i_tx_num_clks  -- in std_logic_vector --number of clocks, "i_clk", per baud period
		);

	UUT_RX: uart_rx
		port map(
			i_clk: in std_logic;
			i_rst: in std_logic;
			i_rx : in std_logic;
			i_num_clks: in std_logic_vector; --number of clocks, "i_clk", per baud period
			o_dat: out std_logic_vector; --data received, typically 8 width, set to 9 if you expect to rx parity
			o_val: out std_logic  -- valid bit, high when data on o_dat is valid.
		);


end arch;
