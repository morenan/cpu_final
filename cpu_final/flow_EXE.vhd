library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use work.com_define.ALL;

entity flow_EXE is
	port(
		clk, rst, pause, clear : in std_logic;
		status : in INT3;
		
		in_pc : in INT32;
		in_rs_en,   in_rt_en,   in_rd_en   : in std_logic;
		in_rs_addr, in_rt_addr, in_rd_addr : in REG_ADDR;
		in_rs_type, in_rt_type, in_rd_type : in std_logic;  -- 0 : com , 1 : cp0
		in_rs_value, in_rt_value : in INT32 ;
		in_alu_op : in ALU_OP ;
		in_alu_selA, in_alu_selB : in ALU_SELECT ;
		in_imme_sign_extend : in INT32 ;
		in_imme_zero_extend : in INT32 ;
		-- to MEM
		in_mem_wen : in std_logic ;
		in_mem_ren : in std_logic ;
		in_mem_sel : in MEM_SELECT ;
		in_tlb_en : in std_logic ;
		in_align_type : in ALIGN_TYPE ;
		in_wb_sel : in WB_SELECT ;
		-- to WB
		in_lo_en, in_hi_en : in std_logic ;
		
		out_pc : out INT32 ;
		out_rs_en,   out_rd_en   : out std_logic ;
		out_rs_addr, out_rd_addr : out REG_ADDR ;
		out_rs_type, out_rd_type : out std_logic ;
		out_rs_value, out_alu_value, out_lo_value, out_hi_value : out INT32 ;
		out_mem_wen : out std_logic ;
		out_mem_ren : out std_logic ;
		out_mem_sel : out MEM_SELECT ;
		out_tlb_en : out std_logic ;
		out_align_type : out ALIGN_TYPE ;
		out_wb_sel : out WB_SELECT ;
		-- to WB
		out_lo_en, out_hi_en : out std_logic ;
		
		-- with alu
		alu_srcA, alu_srcB : out INT32 ;
		alu_opeator : out ALU_OP ;
		alu_value : in INT32 ;
		alu_lo_value, alu_hi_value : in INT32 ;
		-- with reg
		reg_lo_value, reg_hi_value : in INT32 ;
	
		-- data sideway
		pre_rd_en    : in std_logic ;
		pre_rd_addr  : in REG_ADDR ;
		pre_rd_type  : in std_logic ;
		pre_rd_value : in INT32 ;
		pre_lo_en1,    pre_lo_en2,    pre_hi_en1,    pre_hi_en2   : in std_logic;
		pre_lo_value1, pre_lo_value2, pre_hi_value1, pre_hi_value2 : in INT32;
		
		nex_rd_en : out std_logic;
		nex_rd_type : out std_logic;
		nex_rd_addr : out REG_ADDR
		
		);
end flow_EXE;

architecture bhv of flow_EXE is

signal s_pc : INT32 ;
signal s_exc_code : INT5 ;
signal s_rs_en, s_rt_en, s_rd_en : std_logic ;
signal s_rs_addr, s_rt_addr, s_rd_addr : REG_ADDR ;
signal s_rs_type, s_rt_type, s_rd_type : std_logic ;
signal s_rs_value, s_rt_value : INT32;
signal s_alu_op : ALU_OP;
signal s_alu_selA, s_alu_selB : ALU_SELECT ;
signal s_imme_sign_extend : INT32;
signal s_imme_zero_extend : INT32;
signal s_mem_wen : std_logic ;
signal s_mem_ren : std_logic ;
signal s_mem_sel : MEM_SELECT ;
signal s_align_type : ALIGN_TYPE ;
signal s_tlb_en : std_logic ;
signal s_wb_sel : WB_SELECT ;
signal s_eret_en : std_logic ;
signal s_lo_en, s_hi_en : std_logic ;
signal s_pause : std_logic ;

begin
	
	-- data sideway
	nex_rd_en <= '0'     when clear = '1'
			else s_rd_en when pause = '1'
			else in_rd_en;
	nex_rd_type <= s_rd_type when pause = '1'
			else   in_rd_type;
	nex_rd_addr <= s_rd_addr when pause = '1'
			else   in_rd_addr;

	process(rst, clk, pause, clear)
	variable v_rs_value, v_rt_value, v_lo_value, v_hi_value : INT32;
	variable v_rs_addr, v_rd_addr : REG_ADDR;
	variable v2_rs_value : INT32;
	begin
		if rst = '0' then
			s_pc <= (others => '0') ;
			s_rs_en <= '0' ;
			s_rt_en <= '0' ;
			s_rd_en <= '0' ;
			s_mem_wen <= '0' ;
			s_mem_ren <= '0' ;
			s_tlb_en <= '0' ;
			s_eret_en <= '0' ;
			s_lo_en <= '0' ;
			s_hi_en <= '0' ;
		elsif clk'event and clk = '1' and status = "000" then
			if clear = '1' then
				s_pc <= (others => '0') ;
				s_rs_en <= '0' ;
				s_rt_en <= '0' ;
				s_rd_en <= '0' ;
				s_mem_wen <= '0' ;
				s_mem_ren <= '0' ;
				s_tlb_en <= '0' ;
				s_lo_en <= '0' ;
				s_hi_en <= '0' ;
			elsif pause = '0' then
				-- rs, rt value
				if pre_rd_en = '1' and pre_rd_type = in_rs_type and pre_rd_addr = in_rs_addr then
					v_rs_value := pre_rd_value;
				else
					v_rs_value := in_rs_value;
				end if;
				if pre_rd_en = '1' and pre_rd_type = in_rt_type and pre_rd_addr = in_rt_addr then
					v_rt_value := pre_rd_value;
				else  
					v_rt_value := in_rt_value;
				end if;
				if in_rs_type = '1' then
					v_rs_addr := v_rt_value(4 downto 0);
				else
					v_rs_addr := in_rs_addr;
				end if;
				if in_rd_type = '1' then
					v_rd_addr := v_rt_value(4 downto 0);
				else
					v_rd_addr := in_rd_addr;
				end if;
				if pre_rd_en = '1' and pre_rd_type = in_rs_type and pre_rd_addr = v_rs_addr then
					v2_rs_value := pre_rd_value;
				else
					v2_rs_value := v_rs_value;
				end if;
				if pre_lo_en1 = '1' then
					v_lo_value := pre_lo_value1;
				elsif pre_lo_en2 = '1' then
					v_lo_value := pre_lo_value2;
				else
					v_lo_value := reg_lo_value;
				end if;
				if pre_hi_en1 = '1' then
					v_hi_value := pre_hi_value1;
				elsif pre_hi_en2 = '1' then
					v_hi_value := pre_hi_value2;
				else
					v_hi_value := reg_hi_value;
				end if;
				
				s_pc <= in_pc ;
				s_rs_en <= in_rs_en ;
				s_rt_en <= in_rt_en ;
				s_rd_en <= in_rd_en ;
				s_rs_type <= in_rs_type ;
				s_rt_type <= in_rt_type ;
				s_rd_type <= in_rd_type ;
				s_rs_addr <= v_rs_addr ;
				s_rt_addr <= in_rt_addr ;
				s_rd_addr <= v_rd_addr ;
				s_alu_op <= in_alu_op ;
				s_alu_selA <= in_alu_selA ;
				s_alu_selB <= in_alu_selB ;
				s_imme_sign_extend <= in_imme_sign_extend;
				s_imme_zero_extend <= in_imme_zero_extend;
				s_mem_wen <= in_mem_wen ;
				s_mem_ren <= in_mem_ren ;
				s_align_type <= in_align_type ;
				s_tlb_en <= in_tlb_en ;
				s_wb_sel <= in_wb_sel ;
				s_lo_en <= in_lo_en ;
				s_hi_en <= in_hi_en ;
				s_rs_value <= v2_rs_value;
				s_rt_value <= v_rt_value;
				
				-- alu
				alu_opeator <= in_alu_op;
				case in_alu_selA is
					when ALU_SELECT_RS =>
						alu_srcA <= v2_rs_value ;
					when ALU_SELECT_RT =>
						alu_srcA <= v_rt_value ;
					when ALU_SELECT_ZERO =>
						alu_srcA <= (others => '0') ;
					when ALU_SELECT_LO =>
						alu_srcA <= v_lo_value ;
					when ALU_SELECT_HI =>
						alu_srcA <= v_hi_value ;
					when ALU_SELECT_IMME_SIGN_EXTEND =>
						alu_srcA <= in_imme_sign_extend ;
					when ALU_SELECT_IMME_ZERO_EXTEND =>
						alu_srcA <= in_imme_zero_extend ;
					when ALU_SELECT_16 =>
						alu_srcA <= x"00000010" ;
					when others =>
						alu_srcA <= x"00000000" ;
				end case ;
				case in_alu_selB is
					when ALU_SELECT_RS =>
						alu_srcB <= v2_rs_value ;
					when ALU_SELECT_RT =>
						alu_srcB <= v_rt_value ;
					when ALU_SELECT_ZERO =>
						alu_srcB <= (others => '0') ;
					when ALU_SELECT_LO =>
						alu_srcB <= v_lo_value ;
					when ALU_SELECT_HI =>
						alu_srcB <= v_hi_value ;
					when ALU_SELECT_IMME_SIGN_EXTEND =>
						alu_srcB <= in_imme_sign_extend ;
					when ALU_SELECT_IMME_ZERO_EXTEND =>
						alu_srcB <= in_imme_zero_extend ;
					when ALU_SELECT_16 =>
						alu_srcB <= x"00000010" ;
					when others =>
						alu_srcB <= x"00000000" ;
				end case ;
			else
				if pre_rd_en = '1' and pre_rd_type = s_rs_type and pre_rd_addr = s_rs_addr then
					v_rs_value := pre_rd_value;
				else
					v_rs_value := s_rs_value;
				end if;
				if pre_rd_en = '1' and pre_rd_type = s_rt_type and pre_rd_addr = s_rt_addr then
					v_rt_value := pre_rd_value;
				else  
					v_rt_value := s_rt_value;
				end if;
				if in_rs_type = '1' then
					v_rs_addr := v_rt_value(4 downto 0);
				else
					v_rs_addr := s_rs_addr;
				end if;
				if in_rd_type = '1' then
					v_rd_addr := v_rt_value(4 downto 0);
				else
					v_rd_addr := s_rd_addr;
				end if;
				if pre_rd_en = '1' and pre_rd_type = s_rs_type and pre_rd_addr = v_rs_addr then
					v2_rs_value := pre_rd_value;
				else
					v2_rs_value := v_rs_value;
				end if;
				if pre_lo_en1 = '1' then
					v_lo_value := pre_lo_value1;
				elsif pre_lo_en2 = '1' then
					v_lo_value := pre_lo_value2;
				else
					v_lo_value := reg_lo_value;
				end if;
				if pre_hi_en1 = '1' then
					v_hi_value := pre_hi_value1;
				elsif pre_hi_en2 = '1' then
					v_hi_value := pre_hi_value2;
				else
					v_hi_value := reg_hi_value;
				end if;
				s_rs_value <= v2_rs_value;
				s_rt_value <= v_rt_value;
				-- alu
				alu_opeator <= s_alu_op;
				case s_alu_selA is
					when ALU_SELECT_RS =>
						alu_srcA <= v2_rs_value ;
					when ALU_SELECT_RT =>
						alu_srcA <= v_rt_value ;
					when ALU_SELECT_ZERO =>
						alu_srcA <= (others => '0') ;
					when ALU_SELECT_LO =>
						alu_srcA <= v_lo_value ;
					when ALU_SELECT_HI =>
						alu_srcA <= v_hi_value ;
					when ALU_SELECT_IMME_SIGN_EXTEND =>
						alu_srcA <= s_imme_sign_extend ;
					when ALU_SELECT_IMME_ZERO_EXTEND =>
						alu_srcA <= s_imme_zero_extend ;
					when ALU_SELECT_16 =>
						alu_srcA <= x"00000010" ;
					when others =>
						alu_srcA <= x"00000000" ;
				end case ;
				case s_alu_selB is
					when ALU_SELECT_RS =>
						alu_srcB <= v2_rs_value ;
					when ALU_SELECT_RT =>
						alu_srcB <= v_rt_value ;
					when ALU_SELECT_ZERO =>
						alu_srcB <= (others => '0') ;
					when ALU_SELECT_LO =>
						alu_srcB <= v_lo_value ;
					when ALU_SELECT_HI =>
						alu_srcB <= v_hi_value ;
					when ALU_SELECT_IMME_SIGN_EXTEND =>
						alu_srcB <= s_imme_sign_extend ;
					when ALU_SELECT_IMME_ZERO_EXTEND =>
						alu_srcB <= s_imme_zero_extend ;
					when ALU_SELECT_16 =>
						alu_srcB <= x"00000010" ;
					when others =>
						alu_srcB <= x"00000000" ;
				end case ;

			end if;
		end if ;
	end process ;
		
	-- flow write
	process(rst, clk, pause, clear)
	begin
		if rst = '0' then
			out_pc <= (others => '0') ;
			out_rs_en <= '0' ;
			out_rd_en <= '0' ;
			out_mem_wen <= '0' ;
			out_mem_ren <= '0' ;
			out_tlb_en <= '0' ;
			out_lo_en <= '0' ;
			out_hi_en <= '0' ;
		elsif clk'event and clk = '1' then
			if status = "101" then
				out_mem_wen <= s_mem_wen; 
				out_mem_ren <= s_mem_ren;
			elsif status = "110" then
				out_pc <= s_pc ;
				out_rs_en <= s_rs_en ;
				out_rd_en <= s_rd_en ;
				out_rs_addr <= s_rs_addr;
				out_rd_addr <= s_rd_addr; 
				out_rs_type <= s_rs_type;
				out_rd_type <= s_rd_type;
				out_rs_value <= s_rs_value;
				out_alu_value <= alu_value;
				out_lo_value <= alu_lo_value;
				out_hi_value <= alu_hi_value;
				out_mem_sel <= s_mem_sel; 
				out_tlb_en <= s_tlb_en;
				out_align_type <= s_align_type;
				out_wb_sel <= s_wb_sel;
				out_lo_en <= s_lo_en;
				out_hi_en <= s_hi_en;
			end if;
		end if;
	end process ;
	
end bhv ;
