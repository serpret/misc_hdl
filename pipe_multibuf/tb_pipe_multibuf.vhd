


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.tb_common.all;
use std.env.stop;

entity tb_pipe_multibuf is
end entity tb_pipe_multibuf;

architecture tb_arch of tb_pipe_multibuf is

	-- Component declaration for the DUT
	--component pipe_buf
	--generic( 
	--	DAT_WIDTH: integer
	--);
	--port (
	--	clk       : in  std_logic;
	--	rst       : in  std_logic;
	--	down_rdy  : in  std_logic;
	--	up_val    : in  std_logic;
	--	up_dat    : in  std_logic_vector(7 downto 0);
	--	down_val  : out std_logic;
	--	down_dat  : out std_logic_vector(7 downto 0);
	--	up_rdy    : out std_logic
	--);
	--end component;
	
	
	component pipe_multibuf 
	generic(
		DAT_WIDTH: integer;
		NUM_UP_FF: integer   --maximum is 13 
	);
	port(
		clk: in std_logic;
		rst: in std_logic; 
		
		--upstream data port
		u_val: in  std_logic                              ;
		u_rdy: out std_logic                              ;
		u_dat: in  std_logic_vector( DAT_WIDTH-1 downto 0);
		
		--downstream data port
		d_val: out std_logic                               ;
		d_rdy: in  std_logic                               ;
		d_dat: out std_logic_vector( DAT_WIDTH-1 downto 0) 
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
	
	signal val_12: std_logic;
	signal rdy_12: std_logic;
	signal dat_12: std_logic_vector( 7 downto 0);
	
	signal val_23: std_logic;
	signal rdy_23: std_logic;
	signal dat_23: std_logic_vector( 7 downto 0);
	
	signal up_dat_reg1: std_logic_vector(7 downto 0);
	signal up_dat_reg2: std_logic_vector(7 downto 0);
	
	signal up_ing_reg1: std_logic;
	signal up_ing_reg2: std_logic;
	
	signal tb_dat : unsigned(7 downto 0);
	signal tb_dat2: unsigned(7 downto 0);
	

begin

	-- register upstream data by 2 clock cycles
	process( clk) begin
		if rising_edge(clk) then
			up_dat_reg1 <= up_dat;
			up_dat_reg2 <= up_dat_reg1;
			
			--up_ing_reg1 <= up_rdy and up_val;
			--up_ing_reg2 <= up_ing_reg1;
			
		end if;
	end process;
	
	
	dut1: pipe_multibuf
		generic map(
			DAT_WIDTH => 8,
			NUM_UP_FF => 2
		)
		port map (
			clk    => clk,
			rst    => rst,
			
			u_val  => up_val,
			u_rdy  => up_rdy,
			u_dat  => up_dat_reg2,
			
			d_val  => down_val,
			d_rdy  => down_rdy,
			d_dat  => down_dat
		);
		
	
	
	
	

	---- Instantiate the DUT
	----up_val <= val_23;
	--up_rdy <= rdy_23;
	--
	--dut1: pipe_buf
	--	generic map(
	--		DAT_WIDTH => 8 
	--	)
	--	port map (
	--		clk       => clk,
	--		rst       => rst,
	--		up_val    => up_ing_reg2,
	--		--up_rdy    => up_rdy,
	--		up_rdy    => open,
	--		up_dat    => up_dat_reg2,
	--		down_val  => val_12,
	--		down_rdy  => rdy_12,
	--		down_dat  => dat_12
	--	);
	--	
	--	
	---- Instantiate the DUT
	--dut2: pipe_buf
	--	generic map(
	--		DAT_WIDTH => 8 
	--	)
	--	port map (
	--		clk       => clk,
	--		rst       => rst,
	--		up_val    => val_12,
	--		up_rdy    => rdy_12,
	--		up_dat    => dat_12,
	--		down_val  => val_23,
	--		down_rdy  => rdy_23,
	--		down_dat  => dat_23
	--	);
	--	
	
		

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
			wait for 0 ns;
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
			wait for 0 ns;

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
			wait for 0 ns;
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
		
		-- writes twice and check
		up_write( clk, up_val, up_rdy, up_dat, 8x"AA");
		up_write( clk, up_val, up_rdy, up_dat, 8x"55");
		
		wait until down_val = '1'; 
		assert down_dat = 8x"AA" report "Test10 down_dat failed";
		down_read( clk, down_val, down_rdy);
		
		wait for 0 ns ;
		assert down_dat = 8x"55" report "Test11 down_dat failed";
		down_read( clk, down_val, down_rdy);
				--down_read( clk, down_val, down_rdy);
				
		-- fill up, wait, read make sure good.
		tb_dat <= 8x"01";
		wait for 0 ns;
		
		while up_rdy = '1' loop
			up_write( clk, up_val, up_rdy, up_dat, std_logic_vector( tb_dat) );
			tb_dat <= tb_dat + '1';
			wait for 1 ns;
		end loop;
		
		tb_dat <= 8x"01";
		wait for 0 ns;
		
		while down_val = '1' loop
			assert down_dat = std_logic_vector(tb_dat) report "Test20 down_dat failed";
			down_read( clk, down_val, down_rdy) ;
			tb_dat <= tb_dat + '1';
			wait for 1 ns;
		end loop;
		

		
		-- open downstream ready, full throughput
		down_rdy <= '1';
		up_val <= '1';
		tb_dat <= 8x"01";
		tb_dat2<= 8x"01";
		wait for 0 ns;
		
		for i in 0 to 19 loop
			
			up_dat <= std_logic_vector(tb_dat);
			if down_val = '1' then
				assert down_dat = std_logic_vector( tb_dat2) report "Test30 down_dat failed";
				tb_dat2 <= tb_dat2 + '1';
			end if;
			
			tb_dat <= tb_dat + '1';
			
			wait until rising_edge(clk);
			wait for 1 ns;
		end loop;
		
		up_val <= '0';
		while down_val = '1' loop
			assert down_dat = std_logic_vector( tb_dat2) report "Test31 down_dat failed";
			tb_dat2 <= tb_dat2 + '1';
			wait until rising_edge(clk);
			wait for 1 ns;
		end loop;
		
		
		
		--wait until rising_edge( clk);
		--assert up_rdy = '0' report "Test3 up_rdy failed";
		--
		--assert down_dat = 8x"AA" report "Test4 down_dat failed";
		--down_read( clk, down_val, down_rdy);
		--wait for 0 ns;
		--assert down_dat = 8x"55" report "Test5 down_dat failed";
		--down_read( clk, down_val, down_rdy);
		--
		--wait until rising_edge( clk);
		--wait for 0 ns;
		--assert down_val = '0' report "Test6 down_val failed";
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

