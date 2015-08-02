library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use work.com_define.ALL;

entity flow_IF is
	port(
		clk, rst, pause, clear : in std_logic;
		status : in INT3;
		
		pc_to_exc : out INT32;
		
		in_exc_pc, in_eret_pc, in_jump_pc, in_branch_pc : in INT32;
		in_pc_sel : in PC_SELECT;
		
		out_inst : out INT32  ;
		out_pc : out INT32  ;
		
		-- with mmu
		mmu_addr : out INT32 ;
		mmu_data : in INT32 ;
		mmu_ready : in std_logic
		
		);
end flow_IF ;

architecture bhv of flow_IF is

signal s_pc : INT32 ; 

begin
	pc_to_exc <= s_pc;
	
	process(rst, pause, clk)
	begin
		if rst = '0' then
			s_pc <= x"90000000";
		elsif clk'event and clk = '1' and status = "000" then
			if clear = '1' then
				s_pc <= ADDR_ZERO_VALUE;
			elsif pause = '0' then
				case in_pc_sel is
				when PC_SELECT_NPC => 
					s_pc <= s_pc + 4;
				when PC_SELECT_BRANCH =>
					s_pc <= in_branch_pc;
				when PC_SELECT_JUMP =>
					s_pc <= in_jump_pc;
				when PC_SELECT_EXC => 
					s_pc <= in_exc_pc;
				when PC_SELECT_ERET => 
					s_pc <= in_eret_pc;
				when others => 
					s_pc <= s_pc;
				end case ;
			end if;
		end if; 
	end process;
	
	mmu_addr <= s_pc + 4 	 	when in_pc_sel = PC_SELECT_NPC
		else	in_branch_pc 	when in_pc_sel = PC_SELECT_BRANCH
		else	in_jump_pc	 	when in_pc_sel = PC_SELECT_JUMP
		else	in_exc_pc	 	when in_pc_sel = PC_SELECT_EXC
		else	in_eret_pc	 	when in_pc_sel = PC_SELECT_ERET
		else	s_pc;
	
	process(rst, clk)
	begin
		if rst = '0' then
			out_pc <= ADDR_ZERO_VALUE;
			out_inst <= (others => '0');
		elsif clk'event and clk = '1' and status = "111" then
			out_pc <= s_pc;
			if mmu_ready = '1' then
				out_inst <= mmu_data;
			else
				out_inst <= (others => '0');
			end if;
		end if ;
	end process ;

end bhv ;
