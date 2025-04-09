
------------------------------------------------------------------------------
-- Originally authored by Sergy Pretetsky 2023
-- 
-- License:
-- There are no restrictions on this software. It would be generous
-- of the user to include this text and author, but is not required.
-- The user may use, reuse, sell, modify, redistribute any portion of this
-- software as the user wants.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
-- DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE 
-- USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------


---- valid ready pipeline multibuffer ---------------------------------------------
-- similar to pipe_buf, however has an option specify number of flip flops
-- in upstream user logic without flow (no valid read, no enable) 
-- for example: if a block ram is connected upstream with read address input
-- and read data output and it takes 3 cycles from address to read then
-- set NUM_UP_FF =3
--


--            ▲  │                  │
--            │  │                  │
--            │  │                  │
--            │  │                  │
--            │  │                  ▼
--            │  │    ┌───────────────────────────┐
--            │  │    │ user logic with multiple  │
--            │  │    │                           │
--            │  │    │ flip flops and no flow    │
--            │  │    │                           │
--            │  │    │ control                   │
--            │  │    │                           │
--            │  │    │                           │
--            │  │    └─────────────┬─────────────┘
--            │  │                  │
--            │  ▼                  ▼
--  ┌─────────┴───────────────────────────────────┐
--  │                                             │
--  │  up_ready  up_valid        up_data          │
--  │                                             │
--  │                                             │
--  │             pipe_multibuf                   │
--  │                                             │
--  │                                             │
--  │down_ready  down_valid      down_data        │
--  │                                             │
--  └────────────┬──────────────────┬─────────────┘
--            ▲  │                  │
--            │  │                  │
--            │  │                  │
--            │  ▼                  ▼


library ieee;
use ieee.std_logic_1164.all;



entity pipe_multibuf is
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
end pipe_multibuf;






--  Example 2 FF upstream. Upstream data A->B-> ... F->G
--  Assume u_val always high.
--  If 0 is in data reg assume not valid data.
--  
--  clock cycle  0 1 2 3 4 5 6 7 8 9 0 1 2
--  ______________________________________
--  
--  u_rdy
--  (output)     1 1 0 0 0 0 0 0 1 1 1 1 1
--  
--  inbound reg  C D E 0 0 0 0 0 0 F G H I
--               B C D E 0 0 0 0 0 0 F G H
--  
--  valid        0 0 0 0 E E 0 0 0 0 0 0 0
--               0 0 0 D D D E 0 0 0 0 0 0
--               0 0 C C C C D E 0 0 0 0 0
--               A B B B B B C D E 0 0 F G
--  
--  d_rdy        1 0 0 0 0 1 1 1 1 1 1 1 1
--  (input)
--  ______________________________________
--

architecture arch of pipe_multibuf is

	--inbound keeps track of incoming data in the upstream flip flopped logic.
	--    left is most downstream, right is most upstream
	--valid keeps track of valid data buffered in this entity.
	--    left is most downstream, right is most  upstream
	--    invariant:
	--    data is always buffered into the next available free spot
	--    this means valid should always have 0 or more valid data items in
	--    its left-most bits, and 0 or more invalid data items in its right-most
	--    bits.  There should never be "bubbles" of valid or invalid bits inside 
	--    the valid register
	
	
	signal u_rdy_internal: std_logic;
	signal d_val_internal: std_logic;
	signal inbound_reg: std_logic_vector( NUM_UP_FF-1 downto 0);
	signal inbound : std_logic;
	signal outbound: std_logic;
	
	type t_reg_arr is array (0 to NUM_UP_FF+1) of std_logic_vector( DAT_WIDTH-1 downto 0);
	signal dat_reg: t_reg_arr;
	
	signal valid: std_logic_vector( NUM_UP_FF+1 downto 0);
	
	
	
	

begin

	--invariant assertion check (only for simulation)
	process (clk) begin
		if rising_edge(clk) then
			
			-- handle most upstream
			if valid(0) = '1' then
				assert valid(1) = '1' report "pipe_multibuf invariant failure 1";
			end if;
			
			-- handle middle
			for i in 1 to (valid'left-1) loop
				if valid(i) = '0' then
					assert valid(i-1) = '0' report "pipe_multibuf invariant failure 2";
				elsif valid(i) = '1' then
					assert valid(i+1) = '1' report "pipe_multibuf invariant failure 3";
				end if;
			end loop;
			
			--handle most downstream
			if valid(valid'left) = '0' then
				assert valid(valid'left-1) = '0' report "pipe_multibuf invariant failure 4";
			end if;
			
		end if;
	end process;

	--if second to most downstream valid reg is still free (not valid)
	--then this block is ready for upstream data
	u_rdy_internal <= not valid(valid'left -1); 
	d_val_internal <= valid( valid'left)  ; 

	outbound <= d_val_internal and d_rdy;
	inbound  <= u_rdy_internal and u_val;
	
	-- figure out inbound_reg
	process( clk) begin
		if rising_edge(clk) then
			if rst = '1' then
				inbound_reg <= (others => '0');
			else
				inbound_reg( 0) <= inbound;
				inbound_reg( inbound_reg'left downto 1) <= inbound_reg( inbound_reg'left -1 downto 0);
			end if;
		end if;
	end process;
	
	
	-- figure out valid registers
	process( clk) begin
		if rising_edge(clk) then
			if rst = '1' then
				valid <= (others => '0');
			else
				--handle most upstream valid (index 0)
				if valid(0) = '0' then
					if valid(1) = '1' and d_rdy = '0' and inbound_reg( inbound_reg'left) = '1' then
						valid(0) <= '1';
						dat_reg(0) <= u_dat;
					end if;
				else -- valid(0) = '1' then
					assert inbound_reg( inbound_reg'left) = '0' report "pipe_multibuf assert1 failure";
					if d_rdy = '1' then
						
						valid(0) <= '0';
						
					end if;
				end if;
				
				-- handle middle valid section
				for i in 1 to (valid'left-1) loop
					
					
					if valid(i) = '0' then
						if valid(i+1) = '1' and d_rdy = '0' and inbound_reg( inbound_reg'left) = '1' then
							valid(i) <= '1';
							dat_reg(i) <= u_dat;
						end if;
					else -- valid(i) = '1' then
						if d_rdy = '1' then
							-- check upstream valid reg, else check inbound_reg, else empty
							if valid(i-1) = '1' then
								valid(i) <= '1';
								dat_reg(i) <= dat_reg(i-1);
							elsif inbound_reg( inbound_reg'left) = '1' then
								valid(i) <= '1';
								dat_reg(i) <= u_dat;
							else
								valid(i) <= '0';
							end if;
						end if;
					end if;
				
				end loop;
				
				--handle most downstream valid (index valid'left)
				if valid(valid'left) = '0' then
					if inbound_reg( inbound_reg'left) = '1' then
						valid(valid'left) <= '1';
						dat_reg(NUM_UP_FF+1) <= u_dat;
					end if;
				else -- valid(valid'left) = '1' then
					if d_rdy = '1' then
						-- check upstream valid reg, else check inbound_reg, else empty
						if valid(valid'left-1) = '1' then
							valid(valid'left) <= '1';
							dat_reg(NUM_UP_FF+1) <= dat_reg(NUM_UP_FF);
						elsif inbound_reg( inbound_reg'left) = '1' then
							valid(valid'left) <= '1';
							dat_reg(NUM_UP_FF+1) <= u_dat;
						else
							valid(valid'left) <= '0';
						end if;
						
					end if;
				end if;
				
			end if;
		end if;
	end process;
	
	
	d_val <= d_val_internal; 
	u_rdy <= u_rdy_internal;
	d_dat <= dat_reg( NUM_UP_FF+1);
	--u_rdy <= '1';


	
	
end arch;

	
	
	