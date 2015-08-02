library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.com_define.ALL;
use work.IDecode_const.ALL;

entity flow_ID is
	port(
		led_rt_value : out INT32;
		
		clk, rst, pause, clear : in std_logic;
		status : in INT3;
		
		pc_to_exc : out INT32;
		
		in_inst : in INT32 ;
		in_pc : in INT32 ;
		
		out_pc : out INT32 ;
		out_rs_en,   out_rt_en,   out_rd_en   : out std_logic ;
		out_rs_addr, out_rt_addr, out_rd_addr : out REG_ADDR ;
		out_rs_type, out_rt_type, out_rd_type : out std_logic ; -- 0 : com , 1 : cp0
		out_rs_value, out_rt_value : out INT32 ;
		out_alu_op : out ALU_OP ;
		out_alu_selA, out_alu_selB : out ALU_SELECT ;
		out_imme_sign_extend : out INT32 ;
		out_imme_zero_extend : out INT32 ;
		-- to MEM
		out_mem_wen : out std_logic ;
		out_mem_ren : out std_logic ;
		out_mem_sel : out MEM_SELECT ;
		out_tlb_en : out std_logic ;
		out_align_type : out ALIGN_TYPE ;
		out_wb_sel : out WB_SELECT ;
		-- to WB
		out_lo_en, out_hi_en : out std_logic ;
		-- to exc
		out_branch_en : out std_logic;
		out_branch_pc : out INT32;
		out_branch_wait : out std_logic;
		out_jump_en : out std_logic;
		out_jump_pc : out INT32;
		out_eret_en : out std_logic;
		out_epc_en : out std_logic;
		out_exc_code : out INT2;
		
		-- with reg
		reg_rs_en, reg_rt_en : out std_logic ;
		reg_rs_addr, reg_rt_addr : out REG_ADDR ;
		reg_rs_value, reg_rt_value : in INT32 ;
		
		-- with cp0
		cp0_rs_en : out std_logic;
		cp0_rs_addr : out REG_ADDR;
		cp0_rs_value : in INT32;
		
		-- data sideway
		pre_rd_en1,    pre_rd_en2    , pre_rd_en3    : in std_logic;
		pre_rd_addr1,  pre_rd_addr2  , pre_rd_addr3  : in REG_ADDR;
		pre_rd_type1,  pre_rd_type2  , pre_rd_type3  : in std_logic;
		pre_rd_value2, pre_rd_value3 : in INT32
		
		);
end flow_ID;

architecture bhv of flow_ID is

-- hi clock signals
signal s_pc : INT32 ;
--signal s_inst : INT32 ;
signal s_exc_code : INT2 ;
signal s_rs_en, s_rt_en, s_rd_en : std_logic ;
signal s_rs_addr, s_rt_addr, s_rd_addr : REG_ADDR ;
signal s_rs_type, s_rt_type, s_rd_type : std_logic ;
signal s_rs_value, s_rt_value : INT32;
signal s_alu_op : ALU_OP ;
signal s_alu_selA, s_alu_selB : ALU_SELECT ;
signal s_cmp_op : COMP_OP ;
signal s_imme_sign_extend : INT32 ;
signal s_imme_zero_extend : INT32 ;
signal s_mem_wen : std_logic ;
signal s_mem_ren : std_logic ;
signal s_mem_sel : MEM_SELECT ;
signal s_align_type : ALIGN_TYPE ;
signal s_tlb_en : std_logic ;
signal s_wb_sel : WB_SELECT ;
signal s_eret_en : std_logic ;
signal s_lo_en, s_hi_en : std_logic ;
signal s_pause : std_logic ;

signal s_jump_en : std_logic;
signal s_epc_en : std_logic;

begin
	
	process(clk, rst, pause)   -- hiclock
		variable First : std_logic_vector(5 downto 0);
		variable Last  : std_logic_vector(5 downto 0);
		variable Ins23 : std_logic;
	begin
		First := in_inst(31 downto 26);
		Last := in_inst(5 downto 0);
		Ins23 := in_inst(23);		-- mfc0 & mtc0
		
		if rst = '0' then
			s_pc <= (others => '0') ;
			--s_inst <= (others => '0') ;
			s_exc_code <= (others => '0') ;
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
				--s_inst <= (others => '0') ;
				s_exc_code <= (others => '0') ;
				s_rs_en <= '0' ;
				s_rt_en <= '0' ;
				s_rd_en <= '0' ;
				s_mem_wen <= '0' ;
				s_mem_ren <= '0' ;
				s_tlb_en <= '0' ;
				s_eret_en <= '0' ;
				s_lo_en <= '0' ;
				s_hi_en <= '0' ;
				s_cmp_op <= COMP_OP_DISABLE;
			elsif pause = '0' then
				s_pc <= in_pc ;
				--s_inst <= in_inst ;
			
				-- lazy setting
				s_rs_en <= '1' ;
				s_rt_en <= '1' ;
			
				-- generate rd_en and wb_sel
				case First is
					when F_ZERO =>  case Last is
										when L_JALR => s_rd_en <= '1'; s_wb_sel <= WB_SELECT_FROM_RPC;
										when L_JR =>   s_rd_en <= '0'; s_wb_sel <= WB_SELECT_DISABLE;
										when L_MULT => s_rd_en <= '0'; s_wb_sel <= WB_SELECT_DISABLE;
										when L_MTLO => s_rd_en <= '0'; s_wb_sel <= WB_SELECT_DISABLE;
										when L_MTHI => s_rd_en <= '0'; s_wb_sel <= WB_SELECT_DISABLE;
										when others => s_rd_en <= '1'; s_wb_sel <= WB_SELECT_FROM_ALU;
									end case;
					-- addiu, slti, sltiu, andi, lui, ori, xori
					when F_ADDIU => s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_ALU ;
					when F_SLTI =>  s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_ALU ;
					when F_SLTIU => s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_ALU ;
					when F_ANDI =>  s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_ALU ;
					when F_LUI =>   s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_ALU ;
					when F_ORI =>   s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_ALU ;
					when F_XORI =>  s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_ALU ;
				
					when F_JAL => s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_RPC ; 
					when F_LW =>  s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_MEM ;
					when F_LB =>  s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_MEMBYTE_SIGN_EXTEND ;
					when F_LBU => s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_MEMBYTE_ZERO_EXTEND ;
					when F_SB =>  s_rd_en <= '0' ; s_wb_sel <= WB_SELECT_FROM_MEMBYTE_ZERO_EXTEND ;
					when F_LHU => s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_MEMINT16_ZERO_EXTEND ;
					when F_SW =>  s_rd_en <= '0' ; s_wb_sel <= WB_SELECT_FROM_MEM ;
					when F_MFC0 => 	if Ins23 = '0' then		-- mfc0
										s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_RS ;
									else						-- mtc0
										s_rd_en <= '1' ; s_wb_sel <= WB_SELECT_FROM_RS ;
									end if;
					-- beq, bgez, bgtz, blez, bltz, bne, j, cache, eret, mtc0, tlbwi
					when others => s_rd_en <= '0' ; s_wb_sel <= WB_SELECT_DISABLE;
				end case;
			
				-- generate imme
				if First = F_ZERO then
					s_imme_zero_extend(4 downto 0) <= in_inst(10 downto 6);
					s_imme_sign_extend(4 downto 0) <= in_inst(10 downto 6);
					s_imme_zero_extend(31 downto 5) <= (others => '0');
					s_imme_sign_extend(31 downto 5) <= (others => in_inst(10));
				elsif First = F_JAL or First = F_J then
					s_imme_zero_extend(25 downto 0) <= in_inst(25 downto 0);
					s_imme_sign_extend(25 downto 0) <= in_inst(25 downto 0);
					s_imme_zero_extend(31 downto 26) <= (others => '0');
					s_imme_sign_extend(31 downto 26) <= (others => in_inst(25));
				else
					s_imme_zero_extend(15 downto 0) <= in_inst(15 downto 0);
					s_imme_sign_extend(15 downto 0) <= in_inst(15 downto 0);
					s_imme_zero_extend(31 downto 16) <= (others => '0');
					s_imme_sign_extend(31 downto 16) <= (others => in_inst(15));
				end if ;
			
				-- generate alu_op, alu_selA, alu_selB
				case First is
					when F_ZERO => 
											case Last is
												when L_ADDU => 
													s_alu_op <= ALU_OP_ADD ; 
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_SLT => 
													s_alu_op <= ALU_OP_CMP ; 
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_SLTU => 
													s_alu_op <= ALU_OP_CMPU ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_SUBU => 
													s_alu_op <= ALU_OP_SUBU ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;	
												when L_MULT => 
													s_alu_op <= ALU_OP_MULT ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_MFLO => 
													s_alu_op <= ALU_OP_SRCA ;
													s_alu_selA <= ALU_SELECT_LO ;
													s_alu_selB <= ALU_SELECT_ZERO ;			
												when L_MFHI => 
													s_alu_op <= ALU_OP_SRCA ;
													s_alu_selA <= ALU_SELECT_HI ;
													s_alu_selB <= ALU_SELECT_ZERO ;
												when L_MTLO => 
													s_alu_op <= ALU_OP_TO_LO ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_ZERO ;
												when L_MTHI => 
													s_alu_op <= ALU_OP_TO_HI ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_ZERO ;
												when L_AND => 
													s_alu_op <= ALU_OP_AND ; 
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_NOR => 
													s_alu_op <= ALU_OP_NOR ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_OR => 
													s_alu_op <= ALU_OP_OR ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_XOR => 
													s_alu_op <= ALU_OP_XOR ;
													s_alu_selA <= ALU_SELECT_RS ;
													s_alu_selB <= ALU_SELECT_RT ;
												when L_SLL =>
													s_alu_op <= ALU_OP_SLL ;
													s_alu_selA <= ALU_SELECT_RT ;
													s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;
												when L_SLLV =>
													s_alu_op <= ALU_OP_SLL ;
													s_alu_selA <= ALU_SELECT_RT ;
													s_alu_selB <= ALU_SELECT_RS ;
												when L_SRA => 
													s_alu_op <= ALU_OP_SRA ;
													s_alu_selA <= ALU_SELECT_RT ;
													s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;
												when L_SRAV =>
													s_alu_op <= ALU_OP_SRA ;
													s_alu_selA <= ALU_SELECT_RT ;
													s_alu_selB <= ALU_SELECT_RS ;
												when L_SRL =>
													s_alu_op <= ALU_OP_SRL ;
													s_alu_selA <= ALU_SELECT_RT ;
													s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;
												when L_SRLV =>
													s_alu_op <= ALU_OP_SRL ;
													s_alu_selA <= ALU_SELECT_RT ;
													s_alu_selB <= ALU_SELECT_RS ;	
												when others => 
													s_alu_op <= ALU_OP_DISABLE ;
											end case;
					when F_ADDIU => 
						s_alu_op <= ALU_OP_ADD ; 
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;
					when F_SLTI => 
						s_alu_op <= ALU_OP_CMP ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;
					when F_SLTIU => 
						s_alu_op <= ALU_OP_CMPU ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_ZERO_EXTEND ;
					when F_ANDI => 
						s_alu_op <= ALU_OP_AND ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_ZERO_EXTEND ;
					when F_LUI => 
						s_alu_op <= ALU_OP_SLL ;
						s_alu_selA <= ALU_SELECT_IMME_ZERO_EXTEND ;
						s_alu_selB <= ALU_SELECT_16 ;
					when F_ORI => 
						s_alu_op <= ALU_OP_OR ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_ZERO_EXTEND ;	
					when F_XORI => 
						s_alu_op <= ALU_OP_XOR ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_ZERO_EXTEND ;	
					when F_LW => 
						s_alu_op <= ALU_OP_ADD ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;	
					when F_SW => 
						s_alu_op <= ALU_OP_ADD ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;
					when F_LB => 
						s_alu_op <= ALU_OP_ADD ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;	
					when F_LBU =>
						s_alu_op <= ALU_OP_ADD ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;		
					when F_SB => 
						s_alu_op <= ALU_OP_ADD ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;	
					when F_LHU => 
						s_alu_op <= ALU_OP_ADD ;
						s_alu_selA <= ALU_SELECT_RS ;
						s_alu_selB <= ALU_SELECT_IMME_SIGN_EXTEND ;	
					when others => 
						s_alu_op <= ALU_OP_DISABLE ;
				end case;
			
				-- generate mem
				case First is
					when F_LW =>
						s_mem_ren <= '1' ;
						s_mem_wen <= '0' ;
					when F_SW =>
						s_mem_ren <= '0' ;
						s_mem_wen <= '1' ;
						s_mem_sel <= MEM_SELECT_FROM_RS ;
					when F_LB =>
						s_mem_ren <= '1' ;
						s_mem_wen <= '0' ;
					when F_LBU =>
						s_mem_ren <= '1' ;
						s_mem_wen <= '0' ;
					when F_SB =>
						s_mem_ren <= '1' ;
						s_mem_wen <= '1' ;
						s_mem_sel <= MEM_SELECT_FROM_RS_BYTE ;
					when F_LHU =>
						s_mem_ren <= '1' ;
						s_mem_wen <= '0' ;
					when others =>
						s_mem_ren <= '0' ;
						s_mem_wen <= '0' ;
				end case ;
			
				-- generate align_type
				if First = F_LB or First = F_LBU or First = F_SB then
					s_align_type <= ALIGN_BYTE;
				elsif First = F_LHU then
					s_align_type <= ALIGN_WORD;
				else
					s_align_type <= ALIGN_QUAD;
				end if;
			
				-- generate tlb_en
				if First = F_TLBWI and Last = L_TLBWI then
					s_tlb_en <= '1';
				else
					s_tlb_en <= '0';
				end if;
			
				-- generate lo_en, hi_en
				if First = F_ZERO and Last = L_MULT then
					s_lo_en <= '1' ;
					s_hi_en <= '1' ;
				elsif First = F_ZERO and Last = L_MTLO then 
					s_lo_en <= '1' ;
					s_hi_en <= '0' ;
				elsif First = F_ZERO and Last = L_MTHI then
					s_lo_en <= '0' ;
					s_hi_en <= '1' ;
				else
					s_lo_en <= '0' ;
					s_hi_en <= '0' ;
				end if ;
	
				case First is
					when F_ZERO => 
											case Last is
												when L_ADDU => s_exc_code <= "00" ;
												when L_SLT =>  s_exc_code <= "00" ;
												when L_SLTU => s_exc_code <= "00" ;
												when L_SUBU => s_exc_code <= "00" ;
												when L_MULT => s_exc_code <= "00" ;
												when L_MFLO => s_exc_code <= "00" ;
												when L_MFHI => s_exc_code <= "00" ;
												when L_MTLO => s_exc_code <= "00" ;
												when L_MTHI => s_exc_code <= "00" ;
												when L_JALR => s_exc_code <= "00" ;
												when L_JR =>   s_exc_code <= "00" ;
												when L_AND =>  s_exc_code <= "00" ;
												when L_NOR =>  s_exc_code <= "00" ;
												when L_OR =>   s_exc_code <= "00" ;
												when L_XOR =>  s_exc_code <= "00" ;
												when L_SLL =>  s_exc_code <= "00" ;
												when L_SLLV => s_exc_code <= "00" ;
												when L_SRA =>  s_exc_code <= "00" ;
												when L_SRAV => s_exc_code <= "00" ;
												when L_SRL =>  s_exc_code <= "00" ;
												when L_SRLV => s_exc_code <= "00" ;
				
												when L_SYSCALL => s_exc_code <= "01" ;
		                                        
												when others => s_exc_code <= "10" ;
											end case;
			
					when F_ADDIU => s_exc_code <= "00";
					when F_SLTI =>  s_exc_code <= "00";
					when F_SLTIU => s_exc_code <= "00";
					when F_ANDI =>  s_exc_code <= "00";
					when F_LUI =>   s_exc_code <= "00";
					when F_ORI =>   s_exc_code <= "00";
					when F_XORI =>  s_exc_code <= "00";
					when F_BEQ =>   s_exc_code <= "00";
					when F_BNE =>   s_exc_code <= "00";
					when F_BGEZ =>  s_exc_code <= "00";
					when F_BGTZ =>  s_exc_code <= "00";
					when F_BLEZ =>  s_exc_code <= "00";
					when F_LW =>    s_exc_code <= "00";
					when F_SW =>    s_exc_code <= "00";
					when F_LB =>    s_exc_code <= "00";
					when F_LBU =>   s_exc_code <= "00";
					when F_SB =>    s_exc_code <= "00";
					when F_LHU =>   s_exc_code <= "00";
				
					when F_J =>     s_exc_code <= "00";
					when F_JAL =>   s_exc_code <= "00";
					when F_CACHE => s_exc_code <= "00";
					when F_ERET =>  s_exc_code <= "00";
					when others =>  s_exc_code <= "10";
				end case;
			
				-- generate cmp_op
				case First is
					when F_BEQ =>   s_cmp_op <= COMP_OP_EQUAL;
					when F_BNE =>   s_cmp_op <= COMP_OP_NOT_EQUAL;
					when F_BGEZ =>  s_cmp_op <= COMP_OP_EQUAL_OR_GREETER_THAN;
					when F_BGTZ =>  s_cmp_op <= COMP_OP_GREETER_THAN;
					when F_BLEZ =>  s_cmp_op <= COMP_OP_LESS_THAN;
					when others =>  s_cmp_op <= COMP_OP_DISABLE;
				end case;
			
				-- generate jump_en, epc_en
				case First is
					when F_ZERO => 
											case Last is
												when L_JALR => s_jump_en <= '1' ; s_epc_en <= '0';
												when L_JR =>   s_jump_en <= '1' ; s_epc_en <= '1';
		                                        
												when others => s_jump_en <= '0' ; s_epc_en <= '0';
											end case;
					when F_J =>     s_jump_en <= '1' ; s_epc_en <= '0';
					when F_JAL =>   s_jump_en <= '1' ; s_epc_en <= '0';
				
					when others =>  s_jump_en <= '0' ; s_epc_en <= '0';
				end case;
				
				-- generate eret_en
				if First = F_ERET and Last = L_ERET then
					s_eret_en <= '1';
				else
					s_eret_en <= '0';
				end if;
			end if;
		end if ;
		
	end process ;
	
	-- generate rs, rt and rd addr
	process(clk, rst, pause)
		variable First : std_logic_vector(5 downto 0);
		variable Last  : std_logic_vector(5 downto 0);
		variable Ins23 : std_logic;
	begin
		First := in_inst(31 downto 26);
		Last := in_inst(5 downto 0);
		Ins23 := in_inst(23);		-- mfc0 & mtc0
		
		if clk'event and clk = '1' then
			if status = "000" and pause = '0' then
				if First = F_MFC0 and Ins23 = '0' then
					s_rt_addr <= in_inst(15 downto 11);
					s_rt_type <= '0';
					--s_rs_addr <= reg_rt_value(4 downto 0);
					--s_rs_type <= '1';
					s_rd_addr <= in_inst(20 downto 16);
					s_rd_type <= '0';
				elsif First = F_MFC0 and Ins23 = '1' then
					s_rs_addr <= in_inst(20 downto 16);
					s_rs_type <= '0';
					s_rt_addr <= in_inst(15 downto 11);
					s_rt_type <= '0';
					--s_rd_addr <= reg_rt_value(4 downto 0) ;
					--s_rd_type <= '1' ;
				elsif First = F_ZERO then
					s_rs_addr <= in_inst(25 downto 21);
					s_rs_type <= '0';
					s_rt_addr <= in_inst(20 downto 16);
					s_rt_type <= '0';
					s_rd_addr <= in_inst(15 downto 11);
					s_rd_type <= '0';
				elsif First = F_BEQ or First = F_BNE then
					s_rs_addr <= in_inst(25 downto 21);
					s_rs_type <= '0';
					s_rt_addr <= in_inst(20 downto 16);
					s_rt_type <= '0';
				else
					s_rs_addr <= in_inst(25 downto 21);
					s_rs_type <= '0';
					s_rd_addr <= in_inst(20 downto 16);
					s_rd_type <= '0';
				end if;
			elsif status = "100" then
				if First = F_MFC0 and Ins23 = '0' then
					s_rs_addr <= s_rt_value(4 downto 0);
					s_rs_type <= '1';
				elsif First = F_MFC0 and Ins23 = '1' then
					s_rd_addr <= s_rt_value(4 downto 0);
					s_rd_type <= '1';
				end if;
			end if;
		end if;
	end process;
	
	-- generate rs, rt, rd value
	process(clk, rst)
	begin
		if clk'event and clk = '1' then
			if status = "011" or status = "110" then
				if pre_rd_en2 = '1' and s_rs_type = pre_rd_type2 and s_rs_addr = pre_rd_addr2 then
					s_rs_value <= pre_rd_value2;
				elsif pre_rd_en3 = '1' and s_rs_type = pre_rd_type3 and s_rs_addr = pre_rd_addr3 then
					s_rs_value <= pre_rd_value3;
				elsif s_rs_type = '0' then
					s_rs_value <= reg_rs_value;
				else
					s_rs_value <= cp0_rs_value;
				end if;
				if pre_rd_en2 = '1' and s_rt_type = pre_rd_type2 and s_rt_addr = pre_rd_addr2 then
					s_rt_value <= pre_rd_value2;
				elsif pre_rd_en3 = '1' and s_rt_type = pre_rd_type3 and s_rt_addr = pre_rd_addr3 then
					s_rt_value <= pre_rd_value3;
				else
					s_rt_value <= reg_rt_value;
				end if;
				if s_cmp_op = COMP_OP_DISABLE then
					s_pause <= '0';
				else
					if pre_rd_en1 = '1' and s_rs_type = pre_rd_type1 and s_rs_addr = pre_rd_addr1 then
						s_pause <= '1';
					elsif pre_rd_en1 = '1' and s_rt_type = pre_rd_type1 and s_rt_addr = pre_rd_addr1 then
						s_pause <= '1';
					else
						s_pause <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
		
	-- branch prediction
	process(clk, rst)
	begin
		if clk'event and clk = '1' and status = "100" then
			case s_cmp_op is
				when COMP_OP_EQUAL =>
					if s_rs_value = s_rt_value then
						out_branch_en <= (not s_pause); 
					else 
						out_branch_en <= '0';
					end if;
				when COMP_OP_NOT_EQUAL =>
					if s_rs_value = s_rt_value then
						out_branch_en <= '0';
					else
						out_branch_en <= (not s_pause); 
					end if;
				when COMP_OP_EQUAL_OR_GREETER_THAN =>
					if signed(s_rs_value) >= 0 then
						out_branch_en <= (not s_pause);
					else
						out_branch_en <= '0';
					end if;
				when COMP_OP_GREETER_THAN =>
					if signed(s_rs_value) > 0 then
						out_branch_en <= (not s_pause);	
					else
						out_branch_en <= '0';
					end if;
				when COMP_OP_LESS_THAN =>
					if signed(s_rs_value) < 0 then
						out_branch_en <= (not s_pause);
					else
						out_branch_en <= '0';
					end if;
				when others =>
					out_branch_en <= '0';
			end case;
			out_jump_en <= s_jump_en;
			out_branch_pc <= s_pc+(s_imme_sign_extend(29 downto 0)&"00");
			out_branch_wait <= s_pause;
			out_jump_pc <= s_pc(31 downto 28) & s_imme_zero_extend(25 downto 0) & "00";
			out_eret_en <= s_eret_en;
			out_epc_en <= s_epc_en;
			out_exc_code <= s_exc_code;
		end if;
	end process;
	
	-- flow write
	process(clk, rst)  
	begin
		if rst = '0' then
			out_pc <= (others => '0');
			out_rs_en <= '0';
			out_rt_en <= '0';
			out_rd_en <= '0';
			out_mem_wen <= '0';
			out_mem_ren <= '0';
			out_tlb_en <= '0';
			out_lo_en <= '0';
			out_hi_en <= '0';
		elsif clk'event and clk = '1' and status = "111" then
			out_pc <= s_pc;
			out_rs_en <= s_rs_en;
			out_rt_en <= s_rt_en;
			out_rd_en <= s_rd_en;
			out_rs_addr <= s_rs_addr;
			out_rt_addr <= s_rt_addr;
			out_rd_addr <= s_rd_addr;
			out_rs_type <= s_rs_type;
			out_rt_type <= s_rt_type;
			out_rd_type <= s_rd_type;
			out_rs_value <= s_rs_value;
			out_rt_value <= s_rt_value;
			out_imme_sign_extend <= s_imme_sign_extend ;
			out_imme_zero_extend <= s_imme_sign_extend ;
			out_alu_op <= s_alu_op;
			out_alu_selA <= s_alu_selA;
			out_alu_selB <= s_alu_selB;
			out_mem_wen <= s_mem_wen;
			out_mem_ren <= s_mem_ren;
			out_mem_sel <= s_mem_sel;
			out_tlb_en <= s_tlb_en;
			out_lo_en <= s_lo_en;
			out_hi_en <= s_hi_en;
			out_align_type <= s_align_type;
			out_wb_sel <= s_wb_sel;
		end if;
	end process;
	
	-- with exc
	pc_to_exc <= s_pc;
	
	-- with reg
	reg_rs_en <= '1' when s_rs_type = '0' else '0';
	reg_rt_en <= '1' when s_rt_type = '0' else '0';
	reg_rs_addr <= s_rs_addr;
	reg_rt_addr <= s_rt_addr;
	
	-- with cp0
	cp0_rs_en <= '1' when s_rs_type = '1' else '0';
	cp0_rs_addr <= s_rs_addr;
	
end bhv ;
	
