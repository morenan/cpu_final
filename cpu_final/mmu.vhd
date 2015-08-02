library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.com_define.ALL;

entity mmu is
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
end mmu;

architecture bhv of mmu is
			
	-- related to TLB
	-- EntryHi(62 downto 44) EntryLo0(43 downto 24) DV0(23 downto 22) EntryLo1(21 downto 2) DV1(1 downto 0)
	type tlb_mem_block is array(TLB_NUM_ENTRY-1 downto 0) of std_logic_vector(TLB_ENTRY_WIDTH-1 downto 0);
	signal tlb_mem : tlb_mem_block;
	-- a matrix (21*32) to store the temp value
	type tlb_low_temp_value_block is array(20 downto 0) of std_logic_vector(tlb_num_entry*2-1 downto 0);
	signal tlb_low_temp_value : tlb_low_temp_value_block;
	-- virtual_addr equal to which EntryHi
	signal tlb_which_equal : std_logic_vector(tlb_num_entry-1 downto 0);
	-- virtual_addr match which EntryLo
	signal tlb_which_low : std_logic_vector(tlb_num_entry*2-1 downto 0);
	-- result of tlb transfer : address(20 downto 1) and Dirty(0)
	signal tlb_lookup_result : std_logic_vector(20 downto 0);
	signal tlb_missing : std_logic;
	signal tlb_writable : std_logic;
	-- end of tlb signals
	
	signal not_use_mmu : std_logic;
	signal special_com1_status : std_logic := '0';
	
	-- physical address after TLB transform
	-- not the one that give to the physical level
	signal physical_addr : std_logic_vector(31 downto 0);
		
	-- related to serial port
		-- the value of (COM1 + 4)
	signal serial_status_reg : std_logic := '1';
	
	-- exception code
	signal no_exception_accur : std_logic := '1';
	signal exc_counter : std_logic := '0';
	
	-- to physical level registers
	signal to_physical_addr_reg : std_logic_vector(23 downto 0);
	signal to_physical_data_reg : std_logic_vector(31 downto 0);
	signal to_physical_read_enable_reg : std_logic := '0';
	signal to_physical_write_enable_reg : std_logic := '0';
	
begin

	led(15 downto 12) <= tlb_mem(5)(62 downto 59);
	led(11) <= tlb_mem(5)(22);
	led(10) <= tlb_mem(5)(0);
	led(9 downto 6) <= addr_in(31 downto 28);
	led(5) <= tlb_which_equal(5);
	led(4) <= tlb_which_low(10);
	led(3) <= tlb_which_low(11);
	led(2 downto 0) <= "000";

	-- handle TLBWI
	process(clk)
		variable tlb_index : integer range 15 downto 0 := 0;
	begin
		if clk'event and clk = '1' and status = "000" and pause = '0' then
			if tlb_write_en = '1' then
				tlb_index := conv_integer(tlb_write_struct(66 downto 63));
				tlb_mem(tlb_index) <= tlb_write_struct(62 downto 0);
			end if;
		end if;
	end process;
	
	-- handle exception
	process(clk, rst)
	begin
        -- changed on Jan2
        if rst = '0' then
            exc_counter <= '0';
            exc_code <= NO_MEM_EXC;
            
		-- generate and clean exception at negedge
		elsif clk'event and clk = '1' and status = "001" and pause = '0' then
			if exc_counter = '1' then
				exc_counter <= '0';
				exc_code <= NO_MEM_EXC;
			
			else
				-- address alignment exception
				if( (align_type = ALIGN_WORD and addr_in(0) = '1') or (align_type = ALIGN_QUAD and addr_in(1 downto 0) /= "00") ) then
					if ren = '1' and wen = '0' then
						exc_code <= ADE_L;
						exc_counter <= '1';
					elsif wen = '1' and ren = '0' then
						exc_code <= ADE_S;
						exc_counter <= '1';
					end if;
			
				-- tlb missing
				elsif tlb_missing = '1' then
					if ren = '1' and wen = '0' then
						exc_code <= TLB_L;
						exc_counter <= '1';
					elsif wen = '1' and ren = '0' then
						exc_code <= TLB_S;
						exc_counter <= '1';
					end if;
			
				-- tlb modified
				elsif ( tlb_writable = '0') then
					if wen = '1' and ren = '0' then
						exc_code <= TLB_MODIFIED;
						exc_counter <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- clear enable and data and addr on posedge
	-- send information to physical level on negedge
	to_physical_addr <= to_physical_addr_reg;
	to_physical_data <= to_physical_data_reg;
	to_physical_read_enable <= to_physical_read_enable_reg;
	to_physical_write_enable <= to_physical_write_enable_reg;
	
	-- combination logic	
	-- control signal
	not_use_mmu <= '1' when addr_in(31 downto 29) = "100" or addr_in(31 downto 29) = "101"
						 else '0' ;
						 
	special_com1_status <= '1'	when addr_in(31 downto 0) = VIRTUAL_SERIAL_STATUS
									else '0';
									
	physical_addr <= "000" & addr_in(28 downto 0)
							when not_use_mmu = '1'
						  else tlb_lookup_result(20 downto 1) & addr_in(11 downto 0)
						   when not_use_mmu = '0' and tlb_missing = '0'
						  else x"FFFFFFFF";
						  
	no_exception_accur <= '1'
									when (not((align_type = ALIGN_WORD and addr_in(0) = '1') or (align_type = ALIGN_QUAD and addr_in(1 downto 0) /= "00")) )
											and tlb_missing = '0' and tlb_writable = '1'
								 else '0';
								 
	-- to physical_level
	to_physical_addr_reg <= "00" & physical_addr(23 downto 2)	-- Flash
										when physical_addr(31 downto 24) = x"1E"
									else	"010" & physical_addr(22 downto 2)		-- RAM
										when physical_addr(31 downto 23) = "000000000"
									else "1000" & x"00000"							-- serial
										when physical_addr(31 downto 0) = PHYSICAL_SERIAL_DATA
									else "11" & x"000" & physical_addr(11 downto 2)
										when physical_addr(31 downto 12) = x"10000"
									else x"FFFFFF";
					
	to_physical_data_reg <= data_in;
	
	to_physical_read_enable_reg <= '1'
											when( special_com1_status = '0' 
											and no_exception_accur = '1' 
											and from_physical_ready = '1' 
											and ren = '1')
										else '0';
									
	to_physical_write_enable_reg <= '1'
											when( special_com1_status = '0'  
											and no_exception_accur = '1' 
											and from_physical_ready = '1' 
											and wen = '1')
										else '0';
	
	-- to top mem level
	data_out <= x"0000000" & "00" & serial_status_reg & "1"
					when (special_com1_status = '1')
					else from_physical_data;
	
	ready <= from_physical_ready;
	serial_int <= from_physical_serial;
	
	-- register of serial status, return this directly if you load serial status
	serial_status_reg <= '1' 
								when (from_physical_serial = '1')
								else '0';
	
	-- handle TLB check
	-- compare with EntryHi
	tlb_which_equal(0) <= '1' when (tlb_mem(0)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(1) <= '1' when (tlb_mem(1)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(2) <= '1' when (tlb_mem(2)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(3) <= '1' when (tlb_mem(3)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(4) <= '1' when (tlb_mem(4)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(5) <= '1' when (tlb_mem(5)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(6) <= '1' when (tlb_mem(6)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(7) <= '1' when (tlb_mem(7)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(8) <= '1' when (tlb_mem(8)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(9) <= '1' when (tlb_mem(9)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(10) <= '1' when (tlb_mem(10)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(11) <= '1' when (tlb_mem(11)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(12) <= '1' when (tlb_mem(12)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(13) <= '1' when (tlb_mem(13)(62 downto 44) = addr_in(31 downto 13))
									else '0';
	tlb_which_equal(14) <= '1' when (tlb_mem(14)(62 downto 44) = addr_in(31 downto 13))
									else '0';									
	tlb_which_equal(15) <= '1' when (tlb_mem(15)(62 downto 44) = addr_in(31 downto 13))
									else '0';
		
	-- which EntryLo is selected and generate tlb_temp
	tlb_check : for i in tlb_num_entry-1 downto 0 generate
		tlb_which_low(i*2) <= tlb_which_equal(i) and tlb_mem(i)(0) and ( addr_in(12));		
		tlb_which_low(i*2+1) <= tlb_which_equal(i) and tlb_mem(i)(22) and ( not addr_in(12));
	
		tlb_temp : for j in 20 downto 0 generate
			tlb_low_temp_value(j)(i*2) <= tlb_which_low(i*2) and tlb_mem(i)(j+1);
			tlb_low_temp_value(j)(i*2+1) <= tlb_which_low(i*2+1) and tlb_mem(i)(j+23);
		end generate tlb_temp;
	end generate tlb_check;
	
	-- generate lookup result
	-- tlb_lookup_result can be generated with "or reduce" operator in Verilog, but in VHDL it is difficult
	tlb_result : for i in 20 downto 0 generate
		tlb_lookup_result(i) <= tlb_low_temp_value(i)(0) or tlb_low_temp_value(i)(1) or tlb_low_temp_value(i)(2) or tlb_low_temp_value(i)(3) or
										tlb_low_temp_value(i)(4) or tlb_low_temp_value(i)(5) or tlb_low_temp_value(i)(6) or tlb_low_temp_value(i)(7) or
										tlb_low_temp_value(i)(8) or tlb_low_temp_value(i)(9) or tlb_low_temp_value(i)(10) or tlb_low_temp_value(i)(11) or
										tlb_low_temp_value(i)(12) or tlb_low_temp_value(i)(13) or tlb_low_temp_value(i)(14) or tlb_low_temp_value(i)(15) or
										
										tlb_low_temp_value(i)(16) or tlb_low_temp_value(i)(17) or tlb_low_temp_value(i)(18) or tlb_low_temp_value(i)(19) or
										tlb_low_temp_value(i)(20) or tlb_low_temp_value(i)(21) or tlb_low_temp_value(i)(22) or tlb_low_temp_value(i)(23) or
										tlb_low_temp_value(i)(24) or tlb_low_temp_value(i)(25) or tlb_low_temp_value(i)(26) or tlb_low_temp_value(i)(27) or
										tlb_low_temp_value(i)(28) or tlb_low_temp_value(i)(29) or tlb_low_temp_value(i)(30) or tlb_low_temp_value(i)(31);
	end generate tlb_result;
	
	tlb_missing <= not(not_use_mmu or
								tlb_which_low(0) or tlb_which_low(1) or tlb_which_low(2) or tlb_which_low(3) or tlb_which_low(4) or tlb_which_low(5) or
								tlb_which_low(6) or tlb_which_low(7) or tlb_which_low(8) or tlb_which_low(9) or tlb_which_low(10) or tlb_which_low(11) or
								tlb_which_low(12) or tlb_which_low(13) or tlb_which_low(14) or tlb_which_low(15) or tlb_which_low(16) or tlb_which_low(17) or
								tlb_which_low(18) or tlb_which_low(19) or tlb_which_low(20) or tlb_which_low(21) or tlb_which_low(22) or tlb_which_low(23) or
								tlb_which_low(24) or tlb_which_low(25) or tlb_which_low(26) or tlb_which_low(27) or tlb_which_low(28) or tlb_which_low(29) or
								tlb_which_low(30) or tlb_which_low(31)
							);
	tlb_writable <= not_use_mmu or tlb_lookup_result(0);
	
end bhv;
