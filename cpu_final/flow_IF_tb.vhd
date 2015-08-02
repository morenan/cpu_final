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

signal clk : std_logic;
signal rst : std_logic;
signal status : INT3;

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
  -- generate clk
	process
  begin
      wait for 25ns;
      clk <= '0';
      wait for 25ns;
      clk <= '1';
  end process;
  
  rst <= '0',
         '1' after 100ns;
 
  -- generate status
	process(rst, clk)
	begin
		if rst = '0' then
			status <= "000";
		elsif clk'event and clk = '0' then
			status <= status + 1;
		end if;
	end process;
	
	process(rst, clk)
	begin
	  if rst = '0' then
	    pause_if_in <= '0';
	  elsif clk'event and clk = '1' then
	    if status = "111" and pc_id = x"900000f0" then
	      pause_if_in <= '1';
	    else
	      pause_if_in <= '0';
	    end if;
	  end if;
	end process;
	clear_if_in <= '0';
	pc_if_sel <= PC_SELECT_NPC;
	pc_if_exc <= x"00000010";
	pc_if_eret <= x"00000020";
	pc_if_branch <= x"00000030";
	pc_if_jump <= x"00000040";
	exc_if_inst <= x"0f0f0f0f";
  exc_if_ready <= '1';

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

