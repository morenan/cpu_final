LIBRARY ieee  ; 
LIBRARY work  ; 
USE ieee.std_logic_1164.all  ; 
USE ieee.STD_LOGIC_SIGNED.all  ; 
USE work.com_define.all  ; 
USE work.IDecode_const.all  ; 
ENTITY flow_id_tb  IS 
END ; 
 
ARCHITECTURE flow_id_tb_arch OF flow_id_tb IS
  SIGNAL pre_rd_en2   :  STD_LOGIC  ; 
  SIGNAL pre_rd_en3   :  STD_LOGIC  ; 
  SIGNAL out_mem_ren   :  STD_LOGIC  ; 
  SIGNAL in_inst   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_rs_type   :  STD_LOGIC  ; 
  SIGNAL pre_rd_addr1   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL out_branch_pc   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL pre_rd_addr2   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL out_rs_value   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL pre_rd_addr3   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL clk   :  STD_LOGIC  ; 
  SIGNAL out_alu_selA   :  std_logic_vector (2 downto 0)  ; 
  SIGNAL out_alu_selB   :  std_logic_vector (2 downto 0)  ; 
  SIGNAL reg_rs_value   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_rt_addr   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL rst   :  STD_LOGIC  ; 
  SIGNAL out_mem_sel   :  std_logic_vector (1 downto 0)  ; 
  SIGNAL out_eret_en   :  STD_LOGIC  ; 
  SIGNAL out_exc_code   :  std_logic_vector (1 downto 0)  ; 
  SIGNAL out_pc   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL pre_rd_value_en1   :  STD_LOGIC  ; 
  SIGNAL reg_rs_en   :  STD_LOGIC  ; 
  SIGNAL out_mem_wen   :  STD_LOGIC  ; 
  SIGNAL out_hi_en   :  STD_LOGIC  ; 
  SIGNAL status   :  std_logic_vector (2 downto 0)  ; 
  SIGNAL pre_rd_type1   :  STD_LOGIC  ; 
  SIGNAL out_rs_en   :  STD_LOGIC  ; 
  SIGNAL pause   :  STD_LOGIC  ; 
  SIGNAL out_rd_type   :  STD_LOGIC  ; 
  SIGNAL pre_rd_type2   :  STD_LOGIC  ; 
  SIGNAL clear   :  STD_LOGIC  ; 
  SIGNAL pre_rd_type3   :  STD_LOGIC  ; 
  SIGNAL cp0_rs_value   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL pc_to_exc   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_jump_en   :  STD_LOGIC  ; 
  SIGNAL reg_rt_addr   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL out_rs_addr   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL out_imme_sign_extend   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_rd_en   :  STD_LOGIC  ; 
  SIGNAL out_alu_op   :  std_logic_vector (3 downto 0)  ; 
  SIGNAL cp0_rs_addr   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL in_pc   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_branch_wait   :  STD_LOGIC  ; 
  SIGNAL reg_rt_en   :  STD_LOGIC  ; 
  SIGNAL out_rt_type   :  STD_LOGIC  ; 
  SIGNAL out_branch_en   :  STD_LOGIC  ; 
  SIGNAL out_epc_en   :  STD_LOGIC  ; 
  SIGNAL cp0_rs_en   :  STD_LOGIC  ; 
  SIGNAL out_wb_sel   :  std_logic_vector (2 downto 0)  ; 
  SIGNAL out_lo_en   :  STD_LOGIC  ; 
  SIGNAL out_rt_en   :  STD_LOGIC  ; 
  SIGNAL pre_rd_value1   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_rt_value   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL pre_rd_value2   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL pre_rd_value3   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_tlb_en   :  STD_LOGIC  ; 
  SIGNAL out_align_type   :  std_logic_vector (1 downto 0)  ; 
  SIGNAL reg_rs_addr   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL out_imme_zero_extend   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL out_jump_pc   :  std_logic_vector (31 downto 0)  ; 
  SIGNAL pre_rd_en1   :  STD_LOGIC  ; 
  SIGNAL out_rd_addr   :  std_logic_vector (4 downto 0)  ; 
  SIGNAL reg_rt_value   :  std_logic_vector (31 downto 0)  ; 
  
  SIGNAL inst_id : std_logic_vector(2 downto 0);
  COMPONENT flow_ID  
    PORT ( 
      pre_rd_en2  : in STD_LOGIC ; 
      pre_rd_en3  : in STD_LOGIC ; 
      out_mem_ren  : out STD_LOGIC ; 
      in_inst  : in std_logic_vector (31 downto 0) ; 
      out_rs_type  : out STD_LOGIC ; 
      pre_rd_addr1  : in std_logic_vector (4 downto 0) ; 
      out_branch_pc  : out std_logic_vector (31 downto 0) ; 
      pre_rd_addr2  : in std_logic_vector (4 downto 0) ; 
      out_rs_value  : out std_logic_vector (31 downto 0) ; 
      pre_rd_addr3  : in std_logic_vector (4 downto 0) ; 
      clk  : in STD_LOGIC ; 
      out_alu_selA  : out std_logic_vector (2 downto 0) ; 
      out_alu_selB  : out std_logic_vector (2 downto 0) ; 
      reg_rs_value  : in std_logic_vector (31 downto 0) ; 
      out_rt_addr  : out std_logic_vector (4 downto 0) ; 
      rst  : in STD_LOGIC ; 
      out_mem_sel  : out std_logic_vector (1 downto 0) ; 
      out_eret_en  : out STD_LOGIC ; 
      out_exc_code  : out std_logic_vector (1 downto 0) ; 
      out_pc  : out std_logic_vector (31 downto 0) ; 
      pre_rd_value_en1  : in STD_LOGIC ; 
      reg_rs_en  : out STD_LOGIC ; 
      out_mem_wen  : out STD_LOGIC ; 
      out_hi_en  : out STD_LOGIC ; 
      status  : in std_logic_vector (2 downto 0) ; 
      pre_rd_type1  : in STD_LOGIC ; 
      out_rs_en  : out STD_LOGIC ; 
      pause  : in STD_LOGIC ; 
      out_rd_type  : out STD_LOGIC ; 
      pre_rd_type2  : in STD_LOGIC ; 
      clear  : in STD_LOGIC ; 
      pre_rd_type3  : in STD_LOGIC ; 
      cp0_rs_value  : in std_logic_vector (31 downto 0) ; 
      pc_to_exc  : out std_logic_vector (31 downto 0) ; 
      out_jump_en  : out STD_LOGIC ; 
      reg_rt_addr  : out std_logic_vector (4 downto 0) ; 
      out_rs_addr  : out std_logic_vector (4 downto 0) ; 
      out_imme_sign_extend  : out std_logic_vector (31 downto 0) ; 
      out_rd_en  : out STD_LOGIC ; 
      out_alu_op  : out std_logic_vector (3 downto 0) ; 
      cp0_rs_addr  : out std_logic_vector (4 downto 0) ; 
      in_pc  : in std_logic_vector (31 downto 0) ; 
      out_branch_wait  : out STD_LOGIC ; 
      reg_rt_en  : out STD_LOGIC ; 
      out_rt_type  : out STD_LOGIC ; 
      out_branch_en  : out STD_LOGIC ; 
      out_epc_en  : out STD_LOGIC ; 
      cp0_rs_en  : out STD_LOGIC ; 
      out_wb_sel  : out std_logic_vector (2 downto 0) ; 
      out_lo_en  : out STD_LOGIC ; 
      out_rt_en  : out STD_LOGIC ; 
      pre_rd_value1  : in std_logic_vector (31 downto 0) ; 
      out_rt_value  : out std_logic_vector (31 downto 0) ; 
      pre_rd_value2  : in std_logic_vector (31 downto 0) ; 
      pre_rd_value3  : in std_logic_vector (31 downto 0) ; 
      out_tlb_en  : out STD_LOGIC ; 
      out_align_type  : out std_logic_vector (1 downto 0) ; 
      reg_rs_addr  : out std_logic_vector (4 downto 0) ; 
      out_imme_zero_extend  : out std_logic_vector (31 downto 0) ; 
      out_jump_pc  : out std_logic_vector (31 downto 0) ; 
      pre_rd_en1  : in STD_LOGIC ; 
      out_rd_addr  : out std_logic_vector (4 downto 0) ; 
      reg_rt_value  : in std_logic_vector (31 downto 0) ); 
  END COMPONENT ; 
BEGIN
  DUT  : flow_ID  
    PORT MAP ( 
      pre_rd_en2   => pre_rd_en2  ,
      pre_rd_en3   => pre_rd_en3  ,
      out_mem_ren   => out_mem_ren  ,
      in_inst   => in_inst  ,
      out_rs_type   => out_rs_type  ,
      pre_rd_addr1   => pre_rd_addr1  ,
      out_branch_pc   => out_branch_pc  ,
      pre_rd_addr2   => pre_rd_addr2  ,
      out_rs_value   => out_rs_value  ,
      pre_rd_addr3   => pre_rd_addr3  ,
      clk   => clk  ,
      out_alu_selA   => out_alu_selA  ,
      out_alu_selB   => out_alu_selB  ,
      reg_rs_value   => reg_rs_value  ,
      out_rt_addr   => out_rt_addr  ,
      rst   => rst  ,
      out_mem_sel   => out_mem_sel  ,
      out_eret_en   => out_eret_en  ,
      out_exc_code   => out_exc_code  ,
      out_pc   => out_pc  ,
      pre_rd_value_en1   => pre_rd_value_en1  ,
      reg_rs_en   => reg_rs_en  ,
      out_mem_wen   => out_mem_wen  ,
      out_hi_en   => out_hi_en  ,
      status   => status  ,
      pre_rd_type1   => pre_rd_type1  ,
      out_rs_en   => out_rs_en  ,
      pause   => pause  ,
      out_rd_type   => out_rd_type  ,
      pre_rd_type2   => pre_rd_type2  ,
      clear   => clear  ,
      pre_rd_type3   => pre_rd_type3  ,
      cp0_rs_value   => cp0_rs_value  ,
      pc_to_exc   => pc_to_exc  ,
      out_jump_en   => out_jump_en  ,
      reg_rt_addr   => reg_rt_addr  ,
      out_rs_addr   => out_rs_addr  ,
      out_imme_sign_extend   => out_imme_sign_extend  ,
      out_rd_en   => out_rd_en  ,
      out_alu_op   => out_alu_op  ,
      cp0_rs_addr   => cp0_rs_addr  ,
      in_pc   => in_pc  ,
      out_branch_wait   => out_branch_wait  ,
      reg_rt_en   => reg_rt_en  ,
      out_rt_type   => out_rt_type  ,
      out_branch_en   => out_branch_en  ,
      out_epc_en   => out_epc_en  ,
      cp0_rs_en   => cp0_rs_en  ,
      out_wb_sel   => out_wb_sel  ,
      out_lo_en   => out_lo_en  ,
      out_rt_en   => out_rt_en  ,
      pre_rd_value1   => pre_rd_value1  ,
      out_rt_value   => out_rt_value  ,
      pre_rd_value2   => pre_rd_value2  ,
      pre_rd_value3   => pre_rd_value3  ,
      out_tlb_en   => out_tlb_en  ,
      out_align_type   => out_align_type  ,
      reg_rs_addr   => reg_rs_addr  ,
      out_imme_zero_extend   => out_imme_zero_extend  ,
      out_jump_pc   => out_jump_pc  ,
      pre_rd_en1   => pre_rd_en1  ,
      out_rd_addr   => out_rd_addr  ,
      reg_rt_value   => reg_rt_value   ) ; 
      
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
	
	-- generate inst
	process(rst, clk)
	  begin
	    if rst = '0' then
	      inst_id <= "000";
	    elsif clk'event and clk = '1' and status = "111" then
	      inst_id <= inst_id + 1;
	    end if;
	  end process;
	  
	process
	  begin
  case inst_id is
  when "0000" =>
    in_inst <= (others => '0');
  when "0001" =>
    in_inst(31 downto 26) <= F_ZERO;
    in_inst(25 downto 21) <= "00001";
    in_inst(20 downto 16) <= "00010";
    in_inst(15 downto 11) <= "00011";
    in_inst(10 downto 6) <= "00000";
    in_inst(5 downto 0) <= L_ADDU;
  when "0010" =>
    in_inst(31 downto 26) <= F_ZERO;
    in_inst(25 downto 21) <= "00010";
    in_inst(20 downto 16) <= "00001";
    in_inst(15 downto 11) <= "00111";
    in_inst(10 downto 6) <= "00000";
    in_inst(5 downto 0) <= L_SUBU;
  when "0011" =>
    in_inst(31 downto 26) <= F_MFC0;
    in_inst(25 downto 21) <= "00000";
    in_inst(20 downto 16) <= "00011";
    in_inst(15 downto 11) <= "00010";
    in_inst(10 downto 0) <= (others => '0');
  when "0100" =>
    in_inst(31 downto 26) <= F_MFC0;
    in_inst(25 downto 21) <= "00100";
    in_inst(20 downto 16) <= "00001";
    in_inst(15 downto 11) <= "00010";
    in_inst(10 downto 0) <= (others => '0');
  when "0101" =>
	in_inst(31 downto 26) <= F_LW;
	in_inst(25 downto 21) <= "00111";
	in_inst(20 downto 16) <= "00010";
	in_inst(15 downto 0) <= x"00001111";
  when "0110" =>
	in_inst(31 downto 26) <= F_SB;
	in_inst(25 downto 21) <= "00110";
	in_inst(20 downto 16) <= "00011";
	in_inst(15 downto 0) <= x"00000011";
  when "0111" =>
	in_inst(31 downto 26) <= F_BNE;
	in_inst(25 downto 21) <= "00111";
	in_inst(20 downto 16) <= "11001";
	in_inst(15 downto 0) <= x"00001111";
  when "1000" =>
	in_inst(31 downto 26) <= F_BNEZ;
	in_inst(25 downto 21) <= "00001";
	in_inst(20 downto 16) <= "00000";
	in_inst(15 downto 0) <= x"00000011";
  when 
	
end case;
end process;

in_pc(31 downto 3) <= (others => '0');
in_pc(2 downto 0) <= inst_id; 

reg_rs_value <= x"12345678";
reg_rt_value <= x"87654321";
cp0_rs_value <= x"ffffffff";

pre_rd_en1 <= '1';
pre_rd_en2 <= '1';
pre_rd_en3 <= '1';
pre_rd_addr1 <= "00000";
pre_rd_addr2 <= "00001";
pre_rd_addr3 <= "00010";
pre_rd_type1 <= '0';
pre_rd_type2 <= '1';
pre_rd_type3 <= '0';
pre_rd_value1 <= x"22222222";
pre_rd_value2 <= x"33333333";
pre_rd_value3 <= x"44444444";
pre_rd_value_en1 <= '0';

END ; 

