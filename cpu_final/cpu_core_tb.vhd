LIBRARY ieee  ; 
LIBRARY work  ; 
USE ieee.std_logic_1164.all  ; 
USE ieee.std_logic_arith.all  ; 
USE ieee.STD_LOGIC_UNSIGNED.all  ; 
USE work.com_define.all; 


ENTITY flow_IF_tb IS 
END ; 
 
ARCHITECTURE flow_IF_tb_arch OF flow_IF_tb IS 
  COMPONENT flow_IF
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
END COMPONENT ; 
signal pause_if_in : std_logic;
signal clear_if_in : std_logic;
signal pc_if_exc : INT32;
signal pc_if_eret : INT32;
signal pc_if_jump : INT32;
signal pc_if_branch : INT32;
signal pc_if_sel : PC_SELECT;

signal exc_pc_if : INT32;

signal inst_id : INT32;
signal pc_id : INT32;

signal exc_if_addr : INT32;
signal exc_if_inst : INT32;
signal exc_if_ready : std_logic;

BEGIN
  process(clk)
  begin
    clk <= not clk after 50ns;
  end process;
  
  process(rst)
  begin
  rst <= '0',
        '1' after 100ns;
  end process;
 
  -- generate status
	process(rst, clk)
	begin
		if rst = '0' then
			status <= "000";
		elsif clk'event and clk = '0' then
			status <= status + 1;
		end if;
	end process;
	
	process(clk)
	begin
	  if clk'event and clk = '1' then
	    if status = "111" and pc_id = 
	end process;
  
  DUT  : flow_IF
    PORT MAP ( 
      clk => clk, rst => rst, pause => pause_if_in, clear => clear_if_in,
			status => status,
			
			pc_to_exc => exc_pc_if,
			 
			in_exc_pc => pc_if_exc, in_eret_pc => pc_if_eret, in_jump_pc => pc_if_jump, in_branch_pc => pc_if_branch,
			in_pc_sel => pc_if_sel,
		
			out_inst => inst_id,
			out_pc => pc_id,
		
			mmu_addr => exc_if_addr,
			mmu_data => exc_if_inst,
			mmu_ready => exc_if_ready
      
      ) ; 
END ; 

