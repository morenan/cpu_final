library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use work.com_define.ALL;

entity flow_WB is
	port(
		clk, rst, pause, clear : in std_logic;
		status : in INT3;
		
		in_pc : in INT32;
		in_rd_en, in_lo_en, in_hi_en : in std_logic;
		in_rd_value, in_lo_value, in_hi_value : in INT32;
		in_rd_addr : in REG_ADDR;
		in_rd_type : in std_logic;
		
		-- with reg_com
		reg_rd_en, reg_lo_en, reg_hi_en : out std_logic;
		reg_rd_value, reg_lo_value, reg_hi_value : out INT32;
		reg_rd_addr : out REG_ADDR;
		-- with reg_cp0
		cp0_rd_en : out std_logic;
		cp0_rd_addr : out REG_ADDR;
		cp0_rd_value : out INT32;
		
		-- data sideway
		nex_rd_en : out std_logic;
		nex_rd_type : out std_logic;
		nex_rd_addr : out REG_ADDR;
		nex_rd_value : out INT32;
		nex_lo_en, nex_hi_en : out std_logic;
		nex_lo_value, nex_hi_value : out INT32
		
		);
end flow_WB ;

architecture bhv of flow_WB is

signal s_pc : INT32;
signal s_rd_en,		s_lo_en,	s_hi_en 	: std_logic;
signal s_rd_type,	s_lo_type,	s_hi_type	: std_logic;
signal s_rd_addr,	s_lo_addr,	s_hi_addr	: REG_ADDR;
signal s_rd_value,	s_lo_value,	s_hi_value	: INT32;

begin

	-- data sideway
	nex_rd_en <= '0'     when clear = '1'
			else s_rd_en when pause = '1'
			else in_rd_en;
	nex_rd_type <= s_rd_type when pause = '1'
			else   in_rd_type;
	nex_rd_addr <= s_rd_addr when pause = '1'
			else   in_rd_addr;
	nex_rd_value <= s_rd_value when pause = '1'
			else    in_rd_value;
			
	nex_lo_en <= '0' when clear = '1'
		    else s_lo_en when pause = '1'
			else in_lo_en;
	nex_hi_en <= '0' when clear = '1'
			else s_hi_en when pause = '1'
			else in_hi_en;
	nex_lo_value <= s_lo_value when pause = '1'
			else	in_lo_value;
	nex_hi_value <= s_hi_value when pause = '1'
			else	in_hi_value;

	process(rst, clk)
	begin
		if rst = '0' then
			s_pc <= ADDR_ZERO_VALUE;
			s_rd_en <= '0';
			s_lo_en <= '0';
			s_hi_en <= '0';
		elsif clk'event and clk = '1' and status = "000" then
			if clear = '1' then
				s_pc <= ADDR_ZERO_VALUE;
				s_rd_en <= '0';
				s_lo_en <= '0';
				s_hi_en <= '0';
			elsif pause = '0' then
				s_pc <= in_pc;
				s_rd_en <= in_rd_en;
				s_lo_en <= in_lo_en;
				s_hi_en <= in_hi_en;
				s_rd_addr <= in_rd_addr;
				s_rd_type <= in_rd_type;
				s_rd_value <= in_rd_value;
				s_lo_value <= in_lo_value;
				s_hi_value <= in_hi_value;
			end if;
		end if;
	end process;
	
	-- with reg_com
	reg_rd_en <= '0' when clear = '1'
			else s_rd_en when pause = '1' and s_rd_type = '0'
			else in_rd_en when in_rd_type = '0'
			else '0';
	reg_lo_en <= '0' when clear = '1'
			else s_lo_en when pause = '1'
			else in_lo_en;
	reg_hi_en <= '0' when clear = '1'
			else s_hi_en when pause = '1'
			else in_hi_en;
	reg_rd_value <= s_rd_value when pause = '1'
			else in_rd_value;
	reg_lo_value <= s_lo_value when pause = '1'
			else in_lo_value;
	reg_hi_value <= s_hi_value when pause = '1'
			else in_hi_value;
	reg_rd_addr <= s_rd_addr when pause = '1'
			else in_rd_addr;
	
	-- with cp0_com
	cp0_rd_en <= '0' when clear = '1'
			else s_rd_en when pause = '1' and s_rd_type = '1'
			else in_rd_en when in_rd_type = '1'
			else '0';
	cp0_rd_addr <= s_rd_addr when pause = '1'
			else in_rd_addr;
	cp0_rd_value <= s_rd_value when pause = '1'
			else in_rd_value;
	
end bhv;
	
	




