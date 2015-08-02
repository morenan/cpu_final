library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use work.com_define.ALL;

entity flow_MEM is
	port(
		clk, rst, pause, clear : in std_logic;
		status : in INT3;
		
		pc_to_exc : out INT32;
		
		in_pc : in INT32 ;
		in_rs_en,   in_rd_en   : in std_logic ;
		in_rs_addr, in_rd_addr : in REG_ADDR ;
		in_rs_type, in_rd_type : in std_logic ;
		in_rs_value, in_alu_value, in_lo_value, in_hi_value : in INT32 ;
		in_mem_wen : in std_logic;
		in_mem_ren : in std_logic;
		in_mem_sel : in MEM_SELECT;
		in_tlb_en : in std_logic;
		in_align_type : in ALIGN_TYPE;
		in_wb_sel : in WB_SELECT;
		-- to WB
		in_lo_en, in_hi_en : in std_logic ;
		
		out_pc : out INT32 ;
		out_rd_en, out_lo_en, out_hi_en : out std_logic ;
		out_rd_value, out_lo_value, out_hi_value : out INT32 ;
		out_rd_addr : out REG_ADDR ;
		out_rd_type : out std_logic ;
	
		-- with mmu
		mmu_wen, mmu_ren : out std_logic ;
		mmu_addr : out INT32 ;
		mmu_data_in : out INT32 ;
		mmu_data_out : in INT32 ;
		mmu_align_type : out ALIGN_TYPE ;
		mmu_ready : in std_logic ;
		mmu_tlb_en : out std_logic;
	
		-- data sideway
		nex_rd_en : out std_logic;
		nex_rd_addr : out REG_ADDR;
		nex_rd_type : out std_logic;
		nex_rd_value : out INT32;
		nex_lo_en, nex_hi_en : out std_logic;
		nex_lo_value, nex_hi_value : out INT32
     		
		);
end flow_MEM;

architecture bhv of flow_MEM is

signal s_pc : INT32 ;
signal s_rs_en, s_rd_en : std_logic;
signal s_rs_addr, s_rd_addr : REG_ADDR;
signal s_rs_type, s_rd_type : std_logic;
signal s_tlb_en : std_logic;
signal s_align_type : ALIGN_TYPE;
signal s_mem_sel : MEM_SELECT;
signal s_wb_sel : WB_SELECT;
signal s_lo_en, s_hi_en : std_logic;
signal s_rs_value : INT32;
signal s_rd_value : INT32;
signal s_alu_value: INT32;
signal s_lo_value : INT32;
signal s_hi_value : INT32;
signal s_pause : std_logic ;
signal s_mem_wen : std_logic;
signal s_mem_ren : std_logic;

-- signals with mmu
signal s_mmu_data_in : INT32 ;
signal s_mmu_data_out : INT32 ;


begin
	
	pc_to_exc <= s_pc;

	mmu_wen <= '0' when clear = '1'
		  else s_mem_wen when pause = '1'
		  else in_mem_wen;
	mmu_ren <= '0' when clear = '1'
		  else s_mem_ren when pause = '1'
		  else in_mem_ren;
	mmu_tlb_en <= '0' when clear = '1'
		  else s_tlb_en when pause = '1'
		  else in_tlb_en;
	mmu_addr <= s_alu_value when pause = '1'
		  else in_alu_value;
	mmu_data_in <= s_rs_value 					 	 when pause = '1' and s_mem_sel = MEM_SELECT_FROM_RS
			  else x"000000"&s_rs_value(7 downto 0)  when pause = '1' and s_mem_sel = MEM_SELECT_FROM_RS_BYTE
			  else in_rs_value 					 	 when in_mem_sel = MEM_SELECT_FROM_RS
			  else x"000000"&in_rs_value(7 downto 0) when in_mem_sel = MEM_SELECT_FROM_RS_BYTE
			  else x"00000000";
	mmu_align_type <= s_align_type when pause = '1'
				else  in_align_type;

	nex_rd_en <= s_rd_en when pause = '1'
			else in_rd_en;
	nex_rd_type <= s_rd_type when pause = '1'
			else   in_rd_type;
	nex_rd_addr <= s_rd_addr when pause = '1'
			else   in_rd_addr;
	nex_rd_value <= s_rs_value   when pause = '1' and s_wb_sel = WB_SELECT_FROM_RS
			  else  s_alu_value  when pause = '1' and s_wb_sel = WB_SELECT_FROM_ALU
			  else  s_pc + 4     when pause = '1' and s_wb_sel = WB_SELECT_FROM_RPC
			  else  in_rs_value  when in_wb_sel = WB_SELECT_FROM_RS
			  else  in_alu_value when in_wb_sel = WB_SELECT_FROM_ALU
			  else  in_pc + 4    when in_wb_sel = WB_SELECT_FROM_RPC
			  else  s_rd_value;
			  
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
			
	out_rd_value <= s_rd_value;

	process(rst, clk, pause, clear)
	begin
		if rst = '0' then
			s_pc <= (others => '0') ;
			s_rs_en <= '0' ;
			s_rd_en <= '0' ;
			s_lo_en <= '0' ;
			s_hi_en <= '0' ;
		elsif clk'event and clk = '1' and status = "000" then
			if clear = '1' then
				s_pc <= (others => '0') ;
				s_rs_en <= '0' ;
				s_rd_en <= '0' ;
				s_lo_en <= '0' ;
				s_hi_en <= '0' ;
			elsif pause = '0' then
				s_pc <= in_pc;
				s_rs_en <= in_rs_en;
				s_rd_en <= in_rd_en;
				s_lo_en <= in_lo_en;
				s_hi_en <= in_hi_en;
				s_alu_value <= in_alu_value;
				s_rs_type <= in_rs_type;
				s_rd_type <= in_rd_type;
				s_rs_addr <= in_rs_addr;
				s_rd_addr <= in_rd_addr;
				s_rs_value <= in_rs_value;
				s_lo_value <= in_lo_value;
				s_hi_value <= in_hi_value;
				s_wb_sel <= in_wb_sel;
				s_mem_wen <= in_mem_wen;
				s_mem_ren <= in_mem_ren;
				s_mem_sel <= in_mem_sel;
				s_tlb_en <= in_tlb_en;
				s_align_type <= in_align_type;
			end if;
		end if;
	end process ;
	
	process(rst, clk)
	begin
		if rst = '0' then
			out_pc <= (others => '0') ;
			out_rd_en <= '0' ;
			out_lo_en <= '0' ;
			out_hi_en <= '0' ;
		elsif clk'event and clk = '1' and status = "111" then
			out_pc <= s_pc ;
			out_rd_en <= s_rd_en ;
			out_lo_en <= s_lo_en ;
			out_hi_en <= s_hi_en ;
			out_rd_addr <= s_rd_addr;
			out_rd_type <= s_rd_type;
			out_lo_value <= s_lo_value;
			out_hi_value <= s_hi_value;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' and status = "111" then
			if s_wb_sel = WB_SELECT_FROM_RS then
				s_rd_value <= s_rs_value;
			elsif s_wb_sel = WB_SELECT_FROM_ALU then
				s_rd_value <= s_alu_value;
			elsif s_wb_sel = WB_SELECT_FROM_RPC then
				s_rd_value <= s_pc + 4;
			elsif s_wb_sel = WB_SELECT_FROM_MEM then
				s_rd_value <= mmu_data_out;
			elsif s_wb_sel = WB_SELECT_FROM_MEMBYTE_SIGN_EXTEND then
				if mmu_data_out(7) = '0' then
					s_rd_value <= x"000000"&mmu_data_out(7 downto 0);
				elsif mmu_data_out(7) = '1' then
					s_rd_value <= x"ffffff"&mmu_data_out(7 downto 0);
				end if;
			elsif s_wb_sel = WB_SELECT_FROM_MEMBYTE_ZERO_EXTEND then
				s_rd_value <= x"000000"&mmu_data_out(7 downto 0); 
			elsif s_wb_sel = WB_SELECT_FROM_MEMINT16_ZERO_EXTEND then
				s_rd_value <= x"0000"&mmu_data_out(15 downto 0);
			end if;
		end if;
	end process;
	
end bhv ;
