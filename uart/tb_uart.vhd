
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is end tb;



architecture arch of tb is

	signal i_tx_clk     : std_logic := '0';
	signal i_tx_rst     : std_logic;
	signal i_tx_val     : std_logic;
	signal o_tx_rdy     : std_logic;
	signal i_tx_dat     : std_logic_vector(3 downto 0);
	signal txrx         : std_logic;
	signal i_tx_num_clks: std_logic_vector(5 downto 0);


	signal i_rx_clk       : std_logic := '0'; 
	signal i_rx_rst       : std_logic; 
	signal i_rx_num_clks  : std_logic_vector(5 downto 0); 
	signal o_rx_dat       : std_logic_vector(3 downto 0); 
	signal o_rx_val       : std_logic; 

	signal tb_rx_dat : std_logic_vector(3 downto 0);
	signal tb_rx_captured : std_logic;


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
	end component;

	component uart_rx is
		port(
			i_clk: in std_logic;
			i_rst: in std_logic;
			i_rx : in std_logic;
			i_num_clks: in std_logic_vector; --number of clocks, "i_clk", per baud period
			o_dat: out std_logic_vector; --data received, typically 8 width, set to 9 if you expect to rx parity
			o_val: out std_logic  -- valid bit, high when data on o_dat is valid.
		);
	end component;
	
begin


	UUT_TX: uart_tx
		port map(
			i_clk      =>i_tx_clk     , -- in std_logic;
			i_rst      =>i_tx_rst     , -- in std_logic;
			i_val      =>i_tx_val     , -- in std_logic;
			o_rdy      =>o_tx_rdy     , --out std_logic;
			i_dat      =>i_tx_dat     , -- in std_logic_vector; --data to transmit, typically 8 width, set to 9 if you want to tx parity
			o_tx       =>txrx         , -- in std_logic;
			i_num_clks =>i_tx_num_clks  -- in std_logic_vector --number of clocks, "i_clk", per baud period
		);

	UUT_RX: uart_rx
		port map(
			i_clk      =>  i_rx_clk      ,     -- in std_logic;
			i_rst      =>  i_rx_rst      ,     -- in std_logic;
			i_rx       =>  txrx          ,     -- in std_logic;
			i_num_clks =>  i_rx_num_clks ,     -- in std_logic_vector; --number of clocks, "i_clk", per baud period
			o_dat      =>  o_rx_dat      ,     -- out std_logic_vector; --data received, typically 8 width, set to 9 if you expect to rx parity
			o_val      =>  o_rx_val           -- out std_logic  -- valid bit, high when data on o_dat is valid.
		);

	i_tx_clk <= not i_tx_clk after 7 ns;
	i_rx_clk <= not i_rx_clk after 5 ns;


	--signal tb_rx_dat : std_logic_vector(3 downto 0);
	proc_tb_rx: process( i_rx_clk) begin
		if rising_edge(i_rx_clk) then
			if o_rx_val = '1' then
				tb_rx_dat <= o_rx_dat;
				tb_rx_captured <= '1';
			else
				tb_rx_captured <= '0';
			end if;
		end if;
	end process;

	

	initial: process 

		procedure wait_clks( 
			signal    clk: in std_logic;
			constant  num: in integer
		) is
		begin
			for i in num downto 1 loop
				wait until rising_edge( clk);
			end loop;
		end procedure;

	begin
		-- reset tx and rx
		i_tx_rst <= '1';
		i_rx_rst <= '1';
		
		-- deassert tx rst
		wait_clks(i_tx_clk, 2);
		i_tx_rst <= '0';

		-- deassert rx rst
		wait_clks(i_rx_clk, 1);
		i_rx_rst <= '0';

		-- setup baud rate period of 5*7*4 = 140ns
		i_tx_num_clks <=  6d"20"; --5*4
		i_rx_num_clks <=  6d"28"; --7*4

		--send data
		wait_clks(i_tx_clk, 2);
		assert o_tx_rdy = '1' report "failure: i_tx_rdy is not ready" severity error;
		i_tx_dat <= 4x"A";
		i_tx_val <= '1';
		wait_clks(i_tx_clk,1);
		i_tx_val <= '0';

		wait_clks(i_tx_clk, 200);
		assert tb_rx_dat = 4x"A" report "failure: UUT_RX failed to receive data" severity error;


		--send more data
		wait_clks(i_tx_clk, 2);
		assert o_tx_rdy = '1' report "failure: i_tx_rdy is not ready" severity error;
		i_tx_dat <= 4x"3";
		i_tx_val <= '1';
		wait_clks(i_tx_clk,1);
		--i_tx_val <= '0';

		wait_clks(i_tx_clk, 200);
		assert tb_rx_dat = 4x"3" report "failure: UUT_RX failed to receive data" severity error;
		
	
		wait;	



	end process;


end arch;
