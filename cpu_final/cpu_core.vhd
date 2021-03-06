library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

use work.com_define.all;

entity cpu_core is
	port(
		clk_in : in std_logic;
		rst : in std_logic;
		
		led: out std_logic_vector(15 downto 0) := X"f0f0";
		dig1: out std_logic_vector(6 downto 0) := "1111111";
	    dig2: out std_logic_vector(6 downto 0) := "1111111";
     
      	   -- ports connected with ram
	   baseram_addr: out PHYSIC_RAM_ADDR ;
	   baseram_data: inout INT32 ;
	   baseram_ce: out std_logic;
	   baseram_oe: out std_logic;
	   baseram_we: out std_logic;
	   extrram_addr: out PHYSIC_RAM_ADDR ;
	   extrram_data: inout INT32 ;
	   extrram_ce: out std_logic;
	   extrram_oe: out std_logic;
	   extrram_we: out std_logic;

	   -- ports connected with flash
	   flash_addr : out PHYSIC_FLASH_ADDR ;
	   flash_data : inout INT16 ;
	   flash_control_ce0 : out  STD_LOGIC;
	   flash_control_ce1 : out  STD_LOGIC;
	   flash_control_ce2 : out  STD_LOGIC;
	   flash_control_byte : out  STD_LOGIC;
	   flash_control_vpen : out  STD_LOGIC;
	   flash_control_rp : out  STD_LOGIC;
	   flash_control_oe : out  STD_LOGIC;
	   flash_control_we : out  STD_LOGIC;

		-- no serial port during test
      serialport_txd : out STD_LOGIC;
      serialport_rxd : in STD_LOGIC

		);
end cpu_core;

architecture bhv of cpu_core is

component flow_IF is
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
end component;

component flow_ID is
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
		cp0_rs_en : out std_logic ;
		cp0_rs_addr : out REG_ADDR ;
		cp0_rs_value : in INT32 ;
		
		-- data sideway
		pre_rd_en1,    pre_rd_en2    , pre_rd_en3    : in std_logic ;
		pre_rd_addr1,  pre_rd_addr2  , pre_rd_addr3  : in REG_ADDR ;
		pre_rd_type1,  pre_rd_type2  , pre_rd_type3  : in std_logic ;
		pre_rd_value2 , pre_rd_value3 : in INT32
 		
		);
end component;

component flow_EXE is
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
end component;

component flow_MEM is
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
end component;

component flow_WB is
	port(
		clk, rst, pause, clear : in std_logic;
		status : in INT3;
		
		in_pc : in INT32 ;
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
end component;

component reg_com
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
end component ;

component reg_cp0
	port(
		clk, rst, pause : in std_logic;
		status : in INT3;
		
		rs_en : in std_logic ;
		rd_en : in std_logic ;
		rs_addr : in REG_ADDR ;
		rd_addr : in REG_ADDR ;
		rs_value : out INT32 ;
		rd_value : in INT32 ;
		
		-- clock count
		clock_int : out std_logic;
		clock_init : in std_logic;
		clock_pause : in std_logic;
			
		-- exception message 
		int_start_in : in std_logic;
		bad_v_addr_in : in INT32;
		entry_hi_in : in INT20;
		entry_hi_out : out INT20;
		cause_in : in INT5;
		int_code_in : in INT6;
		int_code_out : out INT6;
		ebase_out : out INT32;
		-- eret
		eret_en : in std_logic;
		epc_en : in std_logic;
		epc_in : in INT32;
		epc_out : out INT32;
		
		-- tlb message
		tlb_struct_out : out TLB_STRUCT;
	
		-- serial_int transform
		serial_int_in : in std_logic;
		serial_int_out : out std_logic
		
	);
end component ;

component alu
	port(
		clk, rst, pause : in std_logic;
		status : in INT3;
		
		alu_srcA, alu_srcB : in INT32;
		alu_op : in ALU_OP;
		alu_value, lo_value, hi_value : out INT32 
		
	);
end component ;

component mmu
	port(
		led : out INT16;
	
		clk, rst, pause : in std_logic;
		status : in INT3;
		
		-- virtual ports
		addr_in : in INT32 ;
		data_in : in INT32 ;
		data_out : out INT32 ;
		ren : in std_logic ;
		wen : in std_logic ;
		align_type : in ALIGN_TYPE ;
		ready : out std_logic ;
			
       -- tlb ports
       tlb_write_en : in std_logic;
       tlb_write_struct : in TLB_STRUCT;
      
	   -- about execption
	   serial_int : out std_logic;
	   exc_code : out INT3;
	  
		-- send to physical level
		-- the address passed down to physical level of memory
	 	-- RAM:"00" + "0" + address(20 downto 0)    
		-- Flash:"01" + address(21 downto 0)
		-- Serial:"10" + "0000000000000000000000";
		to_physical_addr : out std_logic_vector(23 downto 0);
		to_physical_data : out std_logic_vector(31 downto 0);
	
		to_physical_read_enable : out std_logic;
		to_physical_write_enable : out std_logic;
	
		-- from physical level
		from_physical_data : in std_logic_vector(31 downto 0);
		from_physical_ready : in std_logic;
		from_physical_serial : in std_logic
	  
	);
end component ;

component phy_mem is
    Port (
			clk_f : in std_logic;
           clk : in  STD_LOGIC;
           status : in INT3;
           
           addr : in  STD_LOGIC_VECTOR (23 downto 0);
           data_in : in  STD_LOGIC_VECTOR (31 downto 0);
           data_out : out  STD_LOGIC_VECTOR (31 downto 0) := X"FFFFFFFF";
           write_enable : in  STD_LOGIC;
           read_enable : in  STD_LOGIC;
           busy: out STD_LOGIC := '0';
           serialport_data_ready : out  STD_LOGIC;

           -- ports connected with ram
           baseram_addr: out std_logic_vector(19 downto 0);
           baseram_data: inout std_logic_vector(31 downto 0);
           baseram_ce: out std_logic;
           baseram_oe: out std_logic;
           baseram_we: out std_logic;
           extrram_addr: out std_logic_vector(19 downto 0);
           extrram_data: inout std_logic_vector(31 downto 0);
           extrram_ce: out std_logic;
           extrram_oe: out std_logic;
           extrram_we: out std_logic;
           
           -- ports connected with flash
           flash_addr : out  STD_LOGIC_VECTOR (22 downto 0);
           flash_data : inout  STD_LOGIC_VECTOR (15 downto 0);
           flash_control_ce0 : out  STD_LOGIC;
           flash_control_ce1 : out  STD_LOGIC;
           flash_control_ce2 : out  STD_LOGIC;
           flash_control_byte : out  STD_LOGIC;
           flash_control_vpen : out  STD_LOGIC;
           flash_control_rp : out  STD_LOGIC;
           flash_control_oe : out  STD_LOGIC;
           flash_control_we : out  STD_LOGIC;
           
           -- ports connected with serial port
           serialport_txd : out STD_LOGIC;
           serialport_rxd : in STD_LOGIC
          );
end component;

component Exception
	port(
		clk, rst : in std_logic;
		status : in INT3;
		
		-- pause
		pause_if_out, pause_id_out, pause_exe_out, pause_mem_out, pause_wb_out : out std_logic;
		-- clear
		clear_if_out, clear_id_out, clear_exe_out, clear_mem_out, clear_wb_out : out std_logic;
		
		-- data
		in_if_addr : in INT32;
		out_if_inst : out INT32;
		out_if_ready : out std_logic;
		in_mem_wen, in_mem_ren : in std_logic;
		in_mem_addr : in INT32;
		in_mem_data : in INT32;
		out_mem_data : out INT32;
		out_mem_ready : out std_logic;
		in_mem_tlb_en : in std_logic;
        in_mem_tlb_struct : in TLB_STRUCT;
        in_mem_align_type : in ALIGN_TYPE;
	
		-- exception
		in_clock_int : in std_logic;
		out_clock_init : out std_logic;
		out_clock_pause : out std_logic;
		in_exc_code_id : in INT2;
		
		-- pc
		in_pc_if, in_pc_id, in_pc_mem : INT32;
		
		-- branch & jump & eret
		in_branch_en : in std_logic;
		in_branch_wait : in std_logic;
		in_jump_en : in std_logic;
		in_jump_pc : in INT32;
		out_jump_pc : out INT32;
		out_pc_sel : out PC_SELECT;
		in_eret_en : in std_logic;
		in_epc_en : in std_logic;
		
		-- with cp0
		eret_en : out std_logic;
		out_int_start : out std_logic;
		out_cause : out INT5;
		out_bad_v_addr : out INT32;
		in_int_code : in INT6;
		out_int_code : out INT6;
		in_entry_hi : in INT20;
		out_entry_hi : out INT20;
		out_epc_en : out std_logic;
		out_epc : out INT32;
		
		-- with mmu
		vir_use_status : out std_logic; -- 0:if,  1:mem
		vir_addr : out INT32 ;
		vir_data_in : out INT32 ;
		vir_data_out : in INT32 ;
		vir_align_type : out ALIGN_TYPE ;
		vir_ren : out std_logic ;
		vir_wen : out std_logic ;
		vir_ready : in std_logic ;
		tlb_write_en : out std_logic ;
        tlb_write_struct : out TLB_STRUCT ;
        vir_serial_int : in std_logic ;
	    vir_exc_code : in INT3
	
		);
end component ;

signal cpu_active : std_logic;
-- status
signal status : INT3;

-- flow data
	-- pc
	signal pc_if_branch, pc_if_jump, pc_if_exc, pc_if_eret : INT32;
	signal pc_if_sel : PC_SELECT;
	signal pc_id, pc_exe, pc_mem, pc_wb : INT32;
	-- inst
	signal inst_id : INT32;
	-- rs, rt, rd
	signal rs_exe_en,   rt_exe_en,   rd_exe_en   : std_logic;
	signal rs_exe_addr, rt_exe_addr, rd_exe_addr : REG_ADDR;
	signal rs_exe_type, rt_exe_type, rd_exe_type : std_logic;
	signal rs_exe_value, rt_exe_value : INT32;
	signal rs_mem_en,   rd_mem_en   : std_logic;
	signal rs_mem_addr, rd_mem_addr : REG_ADDR;
	signal rs_mem_type, rd_mem_type : std_logic;
	signal rs_mem_value : INT32;
	signal rd_wb_en   : std_logic;
	signal rd_wb_addr : REG_ADDR;
	signal rd_wb_type : std_logic;
	signal rd_wb_value : INT32;
	-- alu, lo, hi
	signal alu_exe_op : ALU_OP;
	signal alu_exe_selA, alu_exe_selB : ALU_SELECT;
	signal alu_mem_value, lo_mem_value, hi_mem_value : INT32;
	signal lo_wb_value, hi_wb_value : INT32;
	signal lo_exe_en, hi_exe_en, lo_mem_en, hi_mem_en, lo_wb_en, hi_wb_en : std_logic;
	-- imme
	signal imme_exe_zero_extend, imme_mem_zero_extend : INT32;
	signal imme_exe_sign_extend, imme_mem_sign_extend : INT32;
	-- mem
	signal ren_exe, ren_mem : std_logic;
	signal wen_exe, wen_mem : std_logic;
	signal mem_sel_exe, mem_sel_mem : MEM_SELECT;
	signal align_type_exe, align_type_mem : ALIGN_TYPE;
	-- tlb
	signal tlb_en_exe, tlb_en_mem : std_logic;
	signal tlb_struct_mem : TLB_STRUCT;
	-- wb sel
	signal wb_sel_exe, wb_sel_mem : WB_SELECT;
	
-- sideway
	-- id
	signal side_id_rd_en1,   side_id_rd_en2,   side_id_rd_en3 : std_logic;
	signal side_id_rd_addr1, side_id_rd_addr2, side_id_rd_addr3 : REG_ADDR;
	signal side_id_rd_type1, side_id_rd_type2, side_id_rd_type3 : std_logic;
	signal side_id_rd_value1, side_id_rd_value2, side_id_rd_value3 : INT32;
	signal side_id_rd_value_en1 : std_logic;
	signal side_exe_rd_en : std_logic;
	signal side_exe_rd_addr : REG_ADDR;
	signal side_exe_rd_type : std_logic;
	signal side_exe_rd_value : INT32;
	signal side_exe_lo_en1, 	side_exe_lo_en2 : std_logic;
	signal side_exe_hi_en1, 	side_exe_hi_en2 : std_logic;
	signal side_exe_lo_value1, 	side_exe_lo_value2 : INT32;
	signal side_exe_hi_value1,	side_exe_hi_value2 : INT32;
	
-- register
	-- com
	signal com_rs_en,   com_rt_en,   com_rd_en    : std_logic;
	signal com_rs_addr, com_rt_addr, com_rd_addr  : REG_ADDR;
	signal com_rs_value,com_rt_value,com_rd_value : INT32;
	signal com_lo_en_in, 	 com_hi_en_in 	  : std_logic;
	signal com_lo_value_in,  com_hi_value_in  : INT32;
	signal com_lo_en_out, 	 com_hi_en_out	  : std_logic;
	signal com_lo_value_out, com_hi_value_out : INT32;
	-- cp0
	signal cp0_rs_en,   cp0_rd_en    : std_logic;
	signal cp0_rs_addr, cp0_rd_addr  : REG_ADDR;
	signal cp0_rs_value,cp0_rd_value : INT32;
	signal cp0_clock_int : std_logic;
	signal cp0_clock_init : std_logic;
	signal cp0_clock_pause : std_logic;
	signal cp0_eret_en : std_logic;
	signal cp0_eret_pc : INT32;
	signal cp0_int_start_in : std_logic;
	signal cp0_bad_v_addr_in : INT32;
	signal cp0_entry_hi_in : INT20;
	signal cp0_entry_hi_out : INT20;
	signal cp0_cause_in : INT5;
	signal cp0_int_code_in : INT6;
	signal cp0_int_code_out : INT6;
	signal cp0_exc_pc : INT32;
	signal cp0_epc_en : std_logic;
	signal cp0_epc_in : INT32;
	signal cp0_epc_out : INT32;
	signal cp0_serial_int : std_logic;
	
-- alu
	signal alu_srcA, alu_srcB : INT32;
	signal alu_opeator : ALU_OP;
	signal alu_value, alu_lo_value, alu_hi_value : INT32;
	
-- mmu
	-- virtual ports
	signal vir_wen, vir_ren : std_logic;
	signal vir_addr : INT32;
	signal vir_data_in, vir_data_out : INT32;
	signal vir_serial_int : std_logic;
	signal vir_align_type : ALIGN_TYPE;
	signal vir_exc_code : INT3;
	signal vir_ready : std_logic;
	-- tlb ports
	signal vir_tlb_en : std_logic;
	signal vir_tlb_struct : TLB_STRUCT;
	-- physical ports
	signal phy_addr : std_logic_vector(23 downto 0);
	signal phy_data_in, phy_data_out : INT32;
	signal phy_ren, phy_wen : std_logic;
	signal phy_busy, phy_ready : std_logic;
	signal phy_serial : std_logic;
	
-- pause & clear
	-- pause
	signal pause_if_in, pause_id_in, pause_exe_in, pause_mem_in, pause_wb_in : std_logic;
	signal pause_com, pause_cp0, pause_alu, pause_mmu: std_logic;
	-- clear
	signal clear_if_in, clear_id_in, clear_exe_in, clear_mem_in, clear_wb_in : std_logic;
	
	
-- exception
	-- mmu select
		-- id
		signal exc_if_addr : INT32;
		signal exc_if_inst : INT32;
		signal exc_if_ready : std_logic;
		-- mem
		signal exc_mem_wen, exc_mem_ren : std_logic;
		signal exc_mem_addr : INT32;
		signal exc_mem_data_in, exc_mem_data_out : INT32;
		signal exc_mem_ready : std_logic;
		signal exc_mem_align_type : align_TYPE;
		signal exc_tlb_en : std_logic;
		signal exc_tlb_struct : TLB_STRUCT;
		signal exc_align_type : ALIGN_TYPE;
		-- pc
		signal exc_pc_if : INT32;
		signal exc_pc_id : INT32;
		signal exc_pc_mem : INT32;
		-- branch
		signal exc_branch_en : std_logic;
		signal exc_branch_wait : std_logic;
		-- eret
		signal exc_eret_en : std_logic;
		-- jump
		signal exc_jump_en : std_logic;
		signal exc_jump_pc : INT32;
		-- epc
		signal exc_epc_en : std_logic;
		-- exc code
		signal exc_code_id : INT2;

-- test clock
signal clks : INT24;
signal clk : std_logic;

-- test signal
signal led_rt_value : INT32;
signal led_mmu : INT16;

begin
	-- generate test clock
	process(rst, clk_in)
	begin
		if rst = '0' then
			clks <= (others => '0');
		elsif clk_in'event and clk_in = '1' then
			clks <= clks + 1;
		end if;
	end process;
	clk <= clks(23);
	
	-- cpu active
	process(rst, clk)
	begin
		if rst = '0' then
			cpu_active <= '0';
		elsif clk'event and clk = '1' then
			cpu_active <= '1';
		end if;
	end process;

	with to_integer((unsigned(exc_if_addr)/40)mod 10) select
        dig2 <= 
            "1111110" when 0, "0110000" when 1, "1101101" when 2, "1111001" when 3, 
            "0110011" when 4, "1011011" when 5, "1011111" when 6, "1110000" when 7,
            "1111111" when 8, "1111011" when 9, "1001111" when others;
            
    with to_integer((unsigned(exc_if_addr)/4) mod 10) select
        dig1 <= 
            "1111110" when 0, "0110000" when 1, "1101101" when 2, "1111001" when 3, 
            "0110011" when 4, "1011011" when 5, "1011111" when 6, "1110000" when 7,
            "1111111" when 8, "1111011" when 9, "1001111" when others;
	led(15 downto 8) <= phy_data_in(7 downto 0);
	led(7 downto 0) <= phy_data_out(7 downto 0);
	
	-- generate status
	process(rst, clk)
	begin
		if rst = '0' then
			status <= "000";
		elsif clk'event and clk = '0' and cpu_active = '1' then
			status <= status + 1;
		end if;
	end process;
	
	-- units
		-- flow
		u_IF : Flow_IF port map(
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
		);
		--
		u_ID : Flow_ID port map(
			led_rt_value => led_rt_value,
		
			clk => clk, rst => rst, pause => pause_id_in, clear => clear_id_in,
			status => status,
			
			pc_to_exc => exc_pc_id,
			
			in_inst => inst_id,
			in_pc => pc_id,
			
			out_pc => pc_exe,
			out_rs_en => rs_exe_en,     out_rt_en => rt_exe_en,     out_rd_en => rd_exe_en,
			out_rs_addr => rs_exe_addr, out_rt_addr => rt_exe_addr, out_rd_addr => rd_exe_addr,
			out_rs_type => rs_exe_type, out_rt_type => rt_exe_type, out_rd_type => rd_exe_type,
			out_rs_value => rs_exe_value, out_rt_value => rt_exe_value,
			out_alu_op => alu_exe_op, out_alu_selA => alu_exe_selA, out_alu_selB => alu_exe_selB,
			out_imme_sign_extend => imme_exe_sign_extend, 
			out_imme_zero_extend => imme_exe_zero_extend,
			out_mem_wen => wen_exe, out_mem_ren => ren_exe,
			out_mem_sel => mem_sel_exe,
			out_tlb_en => tlb_en_exe,
			out_align_type => align_type_exe,
			out_wb_sel => wb_sel_exe,
			out_lo_en => lo_exe_en, out_hi_en => hi_exe_en,
			out_branch_en => exc_branch_en,
			out_branch_pc => pc_if_branch,
			out_branch_wait => exc_branch_wait,
			out_eret_en => exc_eret_en,
			out_epc_en => exc_epc_en,
			out_jump_en => exc_jump_en,
			out_jump_pc => exc_jump_pc,
			
			reg_rs_en => com_rs_en, 	  reg_rt_en => com_rt_en,
			reg_rs_addr => com_rs_addr,   reg_rt_addr => com_rt_addr,
			reg_rs_value => com_rs_value, reg_rt_value => com_rt_value,
			cp0_rs_en => cp0_rs_en,
			cp0_rs_addr => cp0_rs_addr,
			cp0_rs_value => cp0_rs_value,
		
			pre_rd_en1 => side_id_rd_en1,       pre_rd_en2 => side_id_rd_en2,   	pre_rd_en3 => side_id_rd_en3,
			pre_rd_addr1 => side_id_rd_addr1,   pre_rd_addr2 => side_id_rd_addr2,   pre_rd_addr3 => side_id_rd_addr3,
			pre_rd_type1 => side_id_rd_type1,   pre_rd_type2 => side_id_rd_type2,   pre_rd_type3 => side_id_rd_type3,
			pre_rd_value2 => side_id_rd_value2, pre_rd_value3 => side_id_rd_value3
		);
		--
		u_EXE : Flow_EXE port map(
			clk => clk, rst => rst, pause => pause_exe_in, clear => clear_exe_in,
			status => status,
						
			in_pc => pc_exe,
			in_rs_en => rs_exe_en,     in_rt_en => rt_exe_en,     in_rd_en => rd_exe_en,
			in_rs_addr => rs_exe_addr, in_rt_addr => rt_exe_addr, in_rd_addr => rd_exe_addr,
			in_rs_type => rs_exe_type, in_rt_type => rs_exe_type, in_rd_type => rd_exe_type,
			in_rs_value => rs_exe_value, in_rt_value => rt_exe_value,
			in_alu_op => alu_exe_op, in_alu_selA => alu_exe_selA, in_alu_selB => alu_exe_selB,
			in_imme_sign_extend => imme_exe_sign_extend, 
			in_imme_zero_extend => imme_exe_sign_extend,
			in_mem_wen => wen_exe, in_mem_ren => ren_exe,
			in_mem_sel => mem_sel_exe,
			in_tlb_en => tlb_en_exe,
			in_align_type => align_type_exe,
			in_wb_sel => wb_sel_exe,
			in_lo_en => lo_exe_en, in_hi_en => hi_exe_en,
			
			out_pc => pc_mem,
			out_rs_en => rs_mem_en, 	out_rd_en => rd_mem_en,
			out_rs_addr => rs_mem_addr, out_rd_addr => rd_mem_addr,
			out_rs_type => rs_mem_type, out_rd_type => rd_mem_type,
			out_rs_value => rs_mem_value, 
			out_alu_value => alu_mem_value,
			out_lo_value => lo_mem_value,
			out_hi_value => hi_mem_value,
			out_mem_wen => wen_mem,
			out_mem_ren => ren_mem,
			out_mem_sel => mem_sel_mem,
			out_tlb_en => tlb_en_mem,
			out_align_type => align_type_mem,
			out_wb_sel => wb_sel_mem,
			out_lo_en => lo_mem_en,
			out_hi_en => hi_mem_en,
			
			alu_srcA => alu_srcA,
			alu_srcB => alu_srcB,
			alu_opeator => alu_opeator,
			alu_value => alu_value,
			alu_lo_value => alu_lo_value,
			alu_hi_value => alu_hi_value,
			reg_lo_value => com_lo_value_out,
			reg_hi_value => com_hi_value_out,
			
			pre_rd_en => side_exe_rd_en,
			pre_rd_type => side_exe_rd_type,
			pre_rd_addr => side_exe_rd_addr,
			pre_rd_value => side_exe_rd_value,
			pre_lo_en1 => side_exe_lo_en1,  	 pre_lo_en2 => side_exe_lo_en2,
			pre_hi_en1 => side_exe_hi_en1,  	 pre_hi_en2 => side_exe_hi_en2,
			pre_lo_value1 => side_exe_lo_value1, pre_lo_value2 => side_exe_lo_value2,
			pre_hi_value1 => side_exe_hi_value1, pre_hi_value2 => side_exe_hi_value2,
			
			nex_rd_en => side_id_rd_en1,
			nex_rd_type => side_id_rd_type1,
			nex_rd_addr => side_id_rd_addr1
		);
		--
		u_MEM : Flow_MEM port map(
			clk => clk, rst => rst, pause => pause_mem_in, clear => clear_mem_in,
			status => status,
			
			pc_to_exc => exc_pc_mem,
			
			in_pc => pc_mem,
			in_rs_en => rs_mem_en, 	   in_rd_en => rd_mem_en,
			in_rs_addr => rs_mem_addr, in_rd_addr => rd_mem_addr,
			in_rs_type => rs_mem_type, in_rd_type => rd_mem_type,
			in_rs_value => rs_mem_value, 
			in_alu_value => alu_mem_value,
			in_lo_value => lo_mem_value,
			in_hi_value => hi_mem_value,
			in_mem_wen => wen_mem,
			in_mem_ren => ren_mem,
			in_mem_sel => mem_sel_mem,
			in_tlb_en => tlb_en_mem,
			in_align_type => align_type_mem,
			in_wb_sel => wb_sel_mem,
			in_lo_en => lo_mem_en,
			in_hi_en => hi_mem_en,
			
			out_pc => pc_wb,
			out_rd_en => rd_wb_en,
			out_lo_en => lo_wb_en,
			out_hi_en => hi_wb_en,
			out_rd_addr => rd_wb_addr,
			out_rd_type => rd_wb_type,
			out_rd_value => rd_wb_value,
			out_lo_value => lo_wb_value,
			out_hi_value => hi_wb_value,
				
			mmu_wen => exc_mem_wen,
			mmu_ren => exc_mem_ren,
			mmu_addr => exc_mem_addr,
			mmu_data_in => exc_mem_data_in,
			mmu_data_out => exc_mem_data_out,
			mmu_align_type => exc_mem_align_type,
			mmu_ready => exc_mem_ready,
			mmu_tlb_en => exc_tlb_en,
			
			nex_rd_en => side_exe_rd_en, 
			nex_rd_addr => side_exe_rd_addr,
			nex_rd_type => side_exe_rd_type,
			nex_rd_value => side_exe_rd_value,
			nex_lo_en => side_exe_lo_en1, nex_hi_en => side_exe_hi_en1,
			nex_lo_value => side_exe_lo_value1, nex_hi_value => side_exe_hi_value1
		);
		--
		u_WB : Flow_WB port map(
			clk => clk, rst => rst, pause => pause_wb_in, clear => clear_wb_in,
			status => status,
				
			in_pc => pc_wb,
			in_rd_en => rd_wb_en,
			in_lo_en => lo_wb_en,
			in_hi_en => hi_wb_en,
			in_rd_value => rd_wb_value,
			in_lo_value => lo_wb_value,
			in_hi_value => hi_wb_value,
			in_rd_addr => rd_wb_addr,
			in_rd_type => rd_wb_type,
			
			reg_rd_en => com_rd_en, reg_lo_en => com_lo_en_in, reg_hi_en => com_hi_en_in,
			reg_rd_value => com_rd_value, reg_lo_value => com_lo_value_in, reg_hi_value => com_hi_value_in,
			reg_rd_addr => com_rd_addr,
			cp0_rd_en => cp0_rd_en,
			cp0_rd_addr => cp0_rd_addr,
			cp0_rd_value => cp0_rd_value,
			
			nex_rd_en => side_id_rd_en3, 
			nex_rd_addr => side_id_rd_addr3,
			nex_rd_type => side_id_rd_type3,
			nex_rd_value => side_id_rd_value3,
			nex_lo_en => side_exe_lo_en2, nex_hi_en => side_exe_hi_en2,
			nex_lo_value => side_exe_lo_value2, nex_hi_value => side_exe_hi_value2
		);
		
		-- reg
		u_com : reg_com port map(
			clk => clk, rst => rst, pause => pause_com,
			status => status,
		
			rs_en => com_rs_en, rt_en => com_rt_en, rd_en => com_rd_en,
			rs_addr => com_rs_addr, rt_addr => com_rt_addr, rd_addr => com_rd_addr,
			rs_value => com_rs_value, rt_value => com_rt_value, rd_value => com_rd_value,
			lo_en_in => com_lo_en_in, hi_en_in => com_hi_en_in,
			lo_en_out => com_lo_en_out, hi_en_out => com_hi_en_out,
			lo_value_in => com_lo_value_in, hi_value_in => com_hi_value_in,
			lo_value_out => com_lo_value_out, hi_value_out => com_hi_value_out
		);
		u_cp0 : reg_cp0 port map(
			clk => clk, rst => rst, pause => pause_cp0,
			status => status,
		
			rs_en => cp0_rs_en, rd_en => cp0_rd_en,
			rs_addr => cp0_rs_addr, rd_addr => cp0_rd_addr,
			rs_value => cp0_rs_value, rd_value => cp0_rd_value,
			
			clock_int => cp0_clock_int, 
			clock_init => cp0_clock_init,
			clock_pause => cp0_clock_pause,

			int_start_in => cp0_int_start_in,
			bad_v_addr_in => cp0_bad_v_addr_in,
			entry_hi_in => cp0_entry_hi_in,
			entry_hi_out => cp0_entry_hi_out,
			cause_in => cp0_cause_in,
			int_code_in => cp0_int_code_in,
			int_code_out => cp0_int_code_out,
			ebase_out => pc_if_exc,
			
			eret_en => cp0_eret_en,
			epc_en => cp0_epc_en,
			epc_in => cp0_epc_in,
			epc_out => pc_if_eret,

			tlb_struct_out => exc_tlb_struct,

			serial_int_in => cp0_serial_int,
			serial_int_out => vir_serial_int
		);
		
		-- alu
		u_alu : alu port map(
			clk => clk, rst => rst, pause => pause_alu,
			status => status,
			
			alu_srcA => alu_srcA,
			alu_srcB => alu_srcB,
			alu_op => alu_opeator,
			alu_value => alu_value,
			lo_value => alu_lo_value,
			hi_value => alu_hi_value
		);
		
		-- mmu
		u_mmu : mmu port map(
			led => led_mmu,
			
			clk => clk, rst => rst, pause => pause_mmu,
			status => status,
			
			addr_in => vir_addr,
			data_in => vir_data_in,
			data_out => vir_data_out,
			ren => vir_ren,
			wen => vir_wen,
			align_type => vir_align_type,
			ready => vir_ready,
			
			tlb_write_en => vir_tlb_en,
			tlb_write_struct => vir_tlb_struct,
			
			serial_int => cp0_serial_int,
			exc_code => vir_exc_code,
			
			to_physical_addr => phy_addr,
			to_physical_data => phy_data_in,
			to_physical_read_enable => phy_ren,
			to_physical_write_enable => phy_wen,
			from_physical_data => phy_data_out,
			from_physical_ready => phy_ready,
			from_physical_serial => phy_serial
		);
		
		-- phy_mem
		u_phy : phy_mem port map(
			clk_f => clk_in,
			clk => clk, status => status,
			addr => phy_addr,
			data_in => phy_data_in,
			data_out => phy_data_out,
			write_enable => phy_wen,
			read_enable => phy_ren,
			busy => phy_busy,
			serialport_data_ready => phy_serial,
			
			baseram_addr => baseram_addr,
			baseram_data => baseram_data,
			baseram_ce => baseram_ce,
			baseram_oe => baseram_oe,
			baseram_we => baseram_we,
			extrram_addr => extrram_addr, 
			extrram_data => extrram_data, 
			extrram_ce => extrram_ce, extrram_oe => extrram_oe, 
			extrram_we => extrram_we, 
			flash_addr => flash_addr, 
			flash_data => flash_data, 
			flash_control_ce0 => flash_control_ce0, 
			flash_control_ce1 => flash_control_ce1, 
			flash_control_ce2 => flash_control_ce2, 
			flash_control_byte => flash_control_byte, 
			flash_control_vpen => flash_control_vpen, 
			flash_control_rp => flash_control_rp, 
			flash_control_oe => flash_control_oe, 
			flash_control_we => flash_control_we,
            
            -- change for test
			serialport_txd => serialport_txd,
			serialport_rxd => serialport_rxd
		);
		
		-- Exception
		u_exc : exception port map(
			clk => clk, rst => rst,
			status => status,
			
			pause_if_out => pause_if_in,
			pause_id_out => pause_id_in,
			pause_exe_out => pause_exe_in,
			pause_mem_out => pause_mem_in,
			pause_wb_out => pause_wb_in,
			
			clear_if_out => clear_if_in,
			clear_id_out => clear_id_in,
			clear_exe_out => clear_exe_in,
			clear_mem_out => clear_mem_in,
			clear_wb_out => clear_wb_in,
			
			in_if_addr => exc_if_addr,
			out_if_inst => exc_if_inst,
			out_if_ready => exc_if_ready,
			in_mem_wen => exc_mem_wen,
			in_mem_ren => exc_mem_ren,
			in_mem_addr => exc_mem_addr,
			in_mem_data => exc_mem_data_in,
			out_mem_data => exc_mem_data_out,
			out_mem_ready => exc_mem_ready,
			in_mem_tlb_en => exc_tlb_en,
			in_mem_tlb_struct => exc_tlb_struct,
			in_mem_align_type => exc_align_type,
			
			in_clock_int => cp0_clock_int,
			out_clock_init => cp0_clock_init,
			out_clock_pause => cp0_clock_pause,
			in_exc_code_id => exc_code_id,
					
			in_pc_if => exc_pc_if,
			in_pc_id => exc_pc_id,
			in_pc_mem => exc_pc_mem,
			
			in_branch_en => exc_branch_en,
			in_branch_wait => exc_branch_wait,
			in_eret_en => exc_eret_en,
			in_jump_en => exc_jump_en,
			in_jump_pc => exc_jump_pc,
			out_jump_pc => pc_if_jump,
			in_epc_en => exc_epc_en,
			out_pc_sel => pc_if_sel,
			
			eret_en => cp0_eret_en,
			out_int_start => cp0_int_start_in,
			out_cause => cp0_cause_in,
			out_bad_v_addr => cp0_bad_v_addr_in,
			in_int_code => cp0_int_code_out,
			out_int_code => cp0_int_code_in,
			in_entry_hi => cp0_entry_hi_out,
			out_entry_hi => cp0_entry_hi_in,
			out_epc_en => cp0_epc_en,
			out_epc => cp0_epc_in,
			
			vir_addr => vir_addr,
			vir_data_in => vir_data_in,
			vir_data_out => vir_data_out,
			vir_align_type => vir_align_type,
			vir_ren => vir_ren,
			vir_wen => vir_wen,
			tlb_write_en => vir_tlb_en,
			tlb_write_struct => vir_tlb_struct,
			vir_ready => vir_ready,
			vir_serial_int => vir_serial_int,
			vir_exc_code => vir_exc_code
		);
		
	-- sideway
	side_id_rd_en2 <= side_exe_rd_en;
	side_id_rd_addr2 <= side_exe_rd_addr;
	side_id_rd_type2 <= side_exe_rd_type;
	side_id_rd_value2 <= side_exe_rd_value;
	
	-- constant enable
	com_lo_en_out <= '1';
	com_hi_en_out <= '1';
	pause_com <= '0';
	pause_cp0 <= '0';
	pause_alu <= '0';
	pause_mmu <= '0';
	
	-- transform
	phy_ready <= not phy_busy;
	
end bhv;	

