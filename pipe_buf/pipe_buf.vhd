
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


---- valid ready pipeline buffer ---------------------------------------------
-- this buffer can connect valid/ready signals between FIFOs or other logic.
-- it supports full throughput transferring data every clock cycle.
-- it breaks combinatorial paths between its upstream and downstream data 
--   ports.
-- it has a best case 1 clock cycle delay (steady state full throughput).
-- it has a worst case 2 clock cycle delay (going from steady-state 0
--    throughput after the buffer is filled from upstream and then
--    going to a downstream read)


library ieee;
use ieee.std_logic_1164.all;


entity pipe_buf is
	generic(
		DAT_WIDTH: integer 
	);
	port(
		clk: in std_logic;
		rst: in std_logic; 
		
		--upstream data port
		up_val: in  std_logic                              ;
		up_rdy: out std_logic                              ;
		up_dat: in  std_logic_vector( DAT_WIDTH-1 downto 0);
		
		--downstream data port
		down_val: out std_logic                               ;
		down_rdy: in  std_logic                               ;
		down_dat: out std_logic_vector( DAT_WIDTH-1 downto 0) 
	);
end pipe_buf;


architecture arch of pipe_buf is
	type t_state is ( ST_EMPTY, ST_SINGLE_BUF, ST_DOUBLE_BUF);
	signal state: t_state;
	
	signal int_dat: std_logic_vector( DAT_WIDTH -1 downto 0);
begin
	
	PROC_NXT_ST: process (clk) 
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state <= ST_EMPTY;
			else
				case state is
					when ST_EMPTY =>
						if( up_val = '1') then
							state <= ST_SINGLE_BUF;
						end if;
						
					when ST_SINGLE_BUF =>
						if( up_val = '1' and down_rdy = '0') then
							state <= ST_DOUBLE_BUF;
						elsif ( up_val = '0' and down_rdy = '1') then
							state <= ST_EMPTY;
						end if;
					
					when ST_DOUBLE_BUF =>
						if( down_rdy = '1') then
							state <= ST_SINGLE_BUF;
						end if;
						
					when others => --invalid state
						state <= ST_EMPTY;
				end case;
			end if;
		end if;
	end process PROC_NXT_ST;
	
	PROC_ST_OUTPUTS: process (all) 
	begin
		case state is
			when ST_EMPTY =>
				down_val <= '0';
				up_rdy   <= '1';
				
			when ST_SINGLE_BUF =>
				down_val <= '1';
				up_rdy   <= '1';
				
			when ST_DOUBLE_BUF =>
				down_val <= '1';
				up_rdy   <= '0';
				
			when others => --invalid state
				down_val <= '0';
				up_rdy   <= '0';
				
		end case;
	end process PROC_ST_OUTPUTS;
	
	PROC_DAT: process( clk) 
	begin
		if rising_edge(clk) then
			case state is
				when ST_EMPTY =>
					if( up_val = '1') then
						down_dat <= up_dat;
					end if;
					
				when ST_SINGLE_BUF =>
					--if( up_val = '1') then
					--	down_dat <= up_dat;
					--end if;
					
					if ( up_val = '1' and down_rdy = '1') then
						down_dat <= up_dat;
					end if;
					 
					if( up_val = '1' and down_rdy ='0') then
						int_dat <= up_dat;
					end if;
					
				when ST_DOUBLE_BUF =>
					if( down_rdy = '1' ) then
						down_dat <= int_dat;
					end if;
					
				when others =>
					--invalid state

			end case;
		end if;
	end process PROC_DAT;
	
end arch;

	
	
	