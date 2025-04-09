


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_common.all;
use std.env.stop;

entity tb_pipe_buf is
end entity tb_pipe_buf;

architecture tb_arch of tb_pipe_buf is

	-- Component declaration for the DUT
	component pipe_buf
	generic( 
		DAT_WIDTH: integer
	);
	port (
		clk       : in  std_logic;
		rst       : in  std_logic;
		down_rdy  : in  std_logic;
		up_val    : in  std_logic;
		up_dat    : in  std_logic_vector(7 downto 0);
		down_val  : out std_logic;
		down_dat  : out std_logic_vector(7 downto 0);
		up_rdy    : out std_logic
	);
	end component;
	
	-- TB signals
	signal clk       : std_logic := '0';
	signal rst       : std_logic := '0';
	signal down_rdy  : std_logic := '0';
	signal up_val    : std_logic := '0';
	signal up_dat    : std_logic_vector(7 downto 0) := (others => '0');
	signal down_val  : std_logic;
	signal down_dat  : std_logic_vector(7 downto 0);
	signal up_rdy    : std_logic;
	
	signal data_in   : t_mem(15 downto 0)(7 downto 0);
	signal load_in   : std_logic;
	
	signal val0    : std_logic ;
	signal rdy0    : std_logic ;
	signal dat0    : std_logic_vector(7 downto 0) ;
	
	signal val1    : std_logic ;
	signal rdy1    : std_logic ;
	signal dat1    : std_logic_vector(7 downto 0) ;

begin

	 -- Instantiate the DUT
	 dut: pipe_buf
	 	generic map(
	 		DAT_WIDTH => 8
	 	)
	 	port map (
	 		clk       => clk,
	 		rst       => rst,
	 		up_val    => up_val,
	 		up_rdy    => up_rdy,
	 		up_dat    => up_dat,
	 		down_val  => down_val,
	 		down_rdy  => down_rdy,
	 		down_dat  => down_dat
	 	);
		
	---- Instantiate 3 DUTS for multi DUT test
	--dut1: pipe_buf
	--	generic map(
	--		DAT_WIDTH => 8
	--	)
	--	port map (
	--		clk       => clk,
	--		rst       => rst,
	--		up_val    => up_val,
	--		up_rdy    => up_rdy,
	--		up_dat    => up_dat,
	--		down_val  => val0,
	--		down_rdy  => rdy0,
	--		down_dat  => dat0
	--	);
	--	
	--dut2: pipe_buf
	--	generic map(
	--		DAT_WIDTH => 8
	--	)
	--	port map (
	--		clk       => clk,
	--		rst       => rst,
	--		up_val    => val0,
	--		up_rdy    => rdy0,
	--		up_dat    => dat0,
	--		down_val  => val1,
	--		down_rdy  => rdy1,
	--		down_dat  => dat1
	--	);
	--	
	--dut3: pipe_buf
	--	generic map(
	--		DAT_WIDTH => 8
	--	)
	--	port map (
	--		clk       => clk,
	--		rst       => rst,
	--		up_val    => val1,
	--		up_rdy    => rdy1,
	--		up_dat    => dat1,
	--		down_val  => down_val,
	--		down_rdy  => down_rdy,
	--		down_dat  => down_dat
	--	);
	
		

	-- Clock process
	process
	begin
	--while now < 1000 ns loop
		clk <= '0';
		wait for 5 ns;
		clk <= '1';
		wait for 5 ns;
	--end loop;
	--wait;
	end process;
	
	-- Reset process
	process
	begin
		rst <= '1';
		wait for 10 ns;
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		rst <= '0';
		wait;
	end process;
	
	-- Stimulus process
	process
		procedure wait_clks( 
			signal    clk: in std_logic;
			constant  num: in integer
		) is
		begin
			for i in num downto 1 loop
				wait until rising_edge( clk);
			end loop;
		end procedure;
		
		--upstream write
		procedure up_write(
			signal clk    : in  std_logic;
			signal up_val : out std_logic;
			signal up_rdy :  in std_logic;
			signal up_dat : out std_logic_vector( 7 downto 0);
			
			constant load_dat: std_logic_vector(7 downto 0)
		) is
		begin
			up_dat <= load_dat;
			up_val <= '1';
			wait until rising_edge(clk);
			
			while up_rdy /= '1' loop
				wait until rising_edge(clk);
			end loop;
			up_val <= '0';
		end procedure;
		
		--upstream write variable data
		procedure up_write_var(
			signal clk    : in  std_logic;
			signal up_val : out std_logic;
			signal up_rdy :  in std_logic;
			signal up_dat : out std_logic_vector( 7 downto 0);
			
			variable load_dat: std_logic_vector(7 downto 0)
		) is
		begin
			up_dat <= load_dat;
			up_val <= '1';
			wait until rising_edge(clk);
			
			while up_rdy /= '1' loop
				wait until rising_edge(clk);
			end loop;
			up_val <= '0';
		end procedure;
		
		--downstream read
		procedure down_read(
			signal clk      : in  std_logic;
			signal down_val : in  std_logic;
			signal down_rdy : out std_logic
		) is
		begin
			down_rdy <= '1';
			wait until rising_edge(clk);
			
			while down_val /= '1' loop
				wait until rising_edge(clk);
			end loop;
			down_rdy <= '0';
		end procedure;
		
		variable for_dat: std_logic_vector(7 downto 0);
		variable read_idx: unsigned(7 downto 0);
		variable write_idx: unsigned( 7 downto 0);
		
		variable pause_tested: boolean := false;
		
	begin
		report "================Starting Test==================";

		wait until falling_edge( rst);
		wait until rising_edge( clk);
		
		-- test single -------------------------------------------
		assert up_rdy = '1' report "Test1 up_rdy failed";
		wait_clks( clk, 10);
		assert up_rdy = '1' report "Test2 up_rdy failed";
		
		up_write( clk, up_val, up_rdy, up_dat, 8x"AA");
		up_write( clk, up_val, up_rdy, up_dat, 8x"55");
		wait until rising_edge( clk);
		assert up_rdy = '0' report "Test3 up_rdy failed";
		
		assert down_dat = 8x"AA" report "Test4 down_dat failed";
		down_read( clk, down_val, down_rdy);
		wait for 0 ns;
		assert down_dat = 8x"55" report "Test5 down_dat failed";
		down_read( clk, down_val, down_rdy);
		
		wait until rising_edge( clk);
		wait for 0 ns;
		assert down_val = '0' report "Test6 down_val failed";
		-- end test single ---------------------------------------
		
		-- -- test multiple -----------------------------------------
		-- assert up_rdy   = '1' report "Test1 up_rdy failed";
		-- assert down_val = '0' report "Test1 down_rdy failed";
		-- 
		-- read_idx := 8x"00";
		-- write_idx := 8x"00";
		-- 
		-- -- write and read same time
		-- down_rdy <= '1';
		-- while( write_idx < 16) loop
		-- 
		-- 	
		-- 	--pause for 1 clock cycle with no data just to test
		-- 	if( write_idx = 8x"09" and (not pause_tested)) then
		-- 		pause_tested := true;
		-- 		wait until rising_edge(clk);
		-- 		
		-- 		if down_val = '1' then
		-- 			assert down_dat = std_logic_vector( read_idx) report "Test2 down_dat failed. : " ;
		-- 			assert down_dat = std_logic_vector( read_idx) report "    expected  : " & to_string( read_idx);
		-- 			assert down_dat = std_logic_vector( read_idx) report "    actual    : " & to_string( down_dat);
		-- 
		-- 			read_idx := read_idx + 1;
		-- 		end if;
		-- 		
		-- 	
		-- 	end if;
		-- 	
		-- 	up_write_var( clk, up_val, up_rdy, up_dat, std_logic_vector( write_idx) );
		-- 
		-- 	
		-- 	if down_val = '1' then
		-- 		--wait for 0 ns;
		-- 		assert down_dat = std_logic_vector( read_idx) report "Test2 down_dat failed. : " ;
		-- 		assert down_dat = std_logic_vector( read_idx) report "    expected  : " & to_string( read_idx);
		-- 		assert down_dat = std_logic_vector( read_idx) report "    actual    : " & to_string( down_dat);
		-- 
		-- 		read_idx := read_idx + 1;
		-- 	end if;
		-- 	write_idx := write_idx + 1;
		-- end loop;
		-- 
		-- -- read remaining data out
		-- down_rdy <= '1';
		-- while down_val = '1' loop
		-- 	
		-- 	wait until rising_edge(clk);
		-- 	
		-- 	if down_val = '1' then
		-- 		--wait for 0 ns;
		-- 		assert down_dat = std_logic_vector( read_idx) report "Test3 down_dat failed. : " ;
		-- 		assert down_dat = std_logic_vector( read_idx) report "    expected  : " & to_string( read_idx);
		-- 		assert down_dat = std_logic_vector( read_idx) report "    actual    : " & to_string( down_dat);
		-- 
		-- 		read_idx := read_idx + 1;
		-- 	end if;
		-- end loop;
		-- 
		-- --fill back up until full
		-- down_rdy <= '0';
		-- up_val <= '1';
		-- while up_rdy = '1' loop
		-- 	--up_write_var( clk, up_val, up_rdy, up_dat, std_logic_vector( write_idx) );
		-- 	up_dat <= std_logic_vector( write_idx);
		-- 	wait until rising_edge( clk);
		-- 	write_idx := write_idx + 1;
		-- end loop;
		-- 
		-- -- read remaining data out
		-- down_rdy <= '1';
		-- up_val <= '0';
		-- while down_val = '1' loop
		-- 	
		-- 	wait until rising_edge(clk);
		-- 	
		-- 	if down_val = '1' then
		-- 		--wait for 0 ns;
		-- 		assert down_dat = std_logic_vector( read_idx) report "Test4 down_dat failed. : " ;
		-- 		assert down_dat = std_logic_vector( read_idx) report "    expected  : " & to_string( read_idx);
		-- 		assert down_dat = std_logic_vector( read_idx) report "    actual    : " & to_string( down_dat);
		-- 
		-- 		read_idx := read_idx + 1;
		-- 	end if;
		-- end loop;
		-- 

		-- -- end  test multiple ------------------------------------


		report "Test Done. Check for any test errors above";
		stop;
	end process;
	
end tb_arch;

