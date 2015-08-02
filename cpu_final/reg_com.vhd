library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use work.com_define.ALL;

entity reg_com is
	port(
		clk, rst, pause : in std_logic;
		status : in INT3;
		
		rs_en : in std_logic ;
		rt_en : in std_logic ;
		rd_en : in std_logic ;
		rs_addr : in REG_ADDR ;
		rt_addr : in REG_ADDR ;
		rd_addr : in REG_ADDR ;
		rs_value : out INT32 ;
		rt_value : out INT32 ;
		rd_value : in INT32 ;
		
		lo_en_in, hi_en_in : in std_logic ;
		lo_value_in, hi_value_in : in INT32 ;
		lo_en_out, hi_en_out : in std_logic ;
		lo_value_out, hi_value_out : out INT32
	
		);
end reg_com ;

architecture bhv of reg_com is

type REG_COM_BLOCK is array (31 downto 0) of std_logic_vector(31 downto 0);
signal s_reg : REG_COM_BLOCK ;
signal lo_value, hi_value : INT32 ;

begin

	process(clk, rst, pause)
	begin
		if rst = '0' then
			rs_value <= (others => '0') ;
			rt_value <= (others => '0') ;
		elsif clk'event and clk = '1' and pause = '0' then
			if status(1 downto 0) = "00" then
				if rs_en = '1' then
					rs_value <= s_reg(conv_integer(rs_addr));
				end if;
				if rt_en = '1' then
					rt_value <= s_reg(conv_integer(rt_addr));
				end if;
				if lo_en_out = '1' then
					lo_value_out <= lo_value;
				end if;
				if hi_en_out = '1' then
					hi_value_out <= hi_value;
				end if;
			end if;
		end if ;
	end process ;
	
	process(clk, rst)
	begin
		if rst = '0' then
			for i in 0 to 31 loop
				s_reg(i) <= (others => '0');
			end loop;
		elsif clk'event and clk = '0' then
			if status(1 downto 0) = "01" and pause = '0' then
				if rd_en = '1' then
					s_reg(conv_integer(rd_addr)) <= rd_value;
				end if ;
				if lo_en_in = '1' then
					lo_value <= lo_value_in;
				end if ;
				if hi_en_in = '1' then
					hi_value <= hi_value_in;
				end if ;
			end if;
		end if;
	end process ;
	
end bhv ;

	

