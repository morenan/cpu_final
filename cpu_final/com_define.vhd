--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package com_define is

subtype INT2 is std_logic_vector(1 downto 0);
subtype INT3 is std_logic_vector(2 downto 0);
subtype INT4 is std_logic_vector(3 downto 0);
subtype INT5 is std_logic_vector(4 downto 0);
subtype INT6 is std_logic_vector(5 downto 0);
subtype INT7 is std_logic_vector(6 downto 0);
subtype INT8 is std_logic_vector(7 downto 0);
subtype INT9 is std_logic_vector(8 downto 0);
subtype INT10 is std_logic_vector(9 downto 0);
subtype INT11 is std_logic_vector(10 downto 0);
subtype INT12 is std_logic_vector(11 downto 0);
subtype INT13 is std_logic_vector(12 downto 0);
subtype INT14 is std_logic_vector(13 downto 0);
subtype INT15 is std_logic_vector(14 downto 0);
subtype INT16 is std_logic_vector(15 downto 0);
subtype INT17 is std_logic_vector(16 downto 0);
subtype INT18 is std_logic_vector(17 downto 0);
subtype INT19 is std_logic_vector(18 downto 0);
subtype INT20 is std_logic_vector(19 downto 0);
subtype INT21 is std_logic_vector(20 downto 0);
subtype INT22 is std_logic_vector(21 downto 0);
subtype INT23 is std_logic_vector(22 downto 0);
subtype INT24 is std_logic_vector(23 downto 0);
subtype INT25 is std_logic_vector(24 downto 0);
subtype INT26 is std_logic_vector(25 downto 0);
subtype INT27 is std_logic_vector(26 downto 0);
subtype INT28 is std_logic_vector(27 downto 0);
subtype INT29 is std_logic_vector(28 downto 0);
subtype INT30 is std_logic_vector(29 downto 0);
subtype INT31 is std_logic_vector(30 downto 0);
subtype INT32 is std_logic_vector(31 downto 0);
constant INT32_ZERO : INT32 := x"00000000";
constant INT32_ONE : INT32 := x"00000001";
constant ADDR_ZERO_VALUE : INT32 := x"ffff3f3f";

subtype REG_ADDR is std_logic_vector(4 downto 0);
subtype PHYSIC_RAM_ADDR is std_logic_vector(19 downto 0);
subtype PHYSIC_FLASH_ADDR is std_logic_vector(22 downto 0);

subtype COMP_OP is std_logic_vector(2 downto 0);
constant COMP_OP_DISABLE 				: COMP_OP := "000";
constant COMP_OP_EQUAL 					: COMP_OP := "001";
constant COMP_OP_NOT_EQUAL 				: COMP_OP := "010";
constant COMP_OP_EQUAL_OR_GREETER_THAN	: COMP_OP := "011";
constant COMP_OP_GREETER_THAN 			: COMP_OP := "100";
constant COMP_OP_LESS_THAN 				: COMP_OP := "101";

subtype PC_SELECT is std_logic_vector(2 downto 0);
constant PC_SELECT_DISABLE :PC_SELECT := "000";
constant PC_SELECT_NPC :    PC_SELECT := "001";
constant PC_SELECT_BRANCH : PC_SELECT := "010";
constant PC_SELECT_JUMP :   PC_SELECT := "011";
constant PC_SELECT_EXC :    PC_SELECT := "100";
constant PC_SELECT_ERET :   PC_SELECT := "101";

subtype ALU_OP is std_logic_vector(3 downto 0);
constant ALU_OP_DISABLE : ALU_OP := "0000";
constant ALU_OP_ADD :     ALU_OP := "0001";
constant ALU_OP_CMP :     ALU_OP := "0010";
constant ALU_OP_CMPU :    ALU_OP := "0011";
constant ALU_OP_SUBU :    ALU_OP := "0100";
constant ALU_OP_SRCA :    ALU_OP := "0101";
constant ALU_OP_AND :     ALU_OP := "0110";
constant ALU_OP_NOR :     ALU_OP := "0111";
constant ALU_OP_OR :      ALU_OP := "1000";
constant ALU_OP_XOR :     ALU_OP := "1001";
constant ALU_OP_SLL :     ALU_OP := "1010";
constant ALU_OP_SRA :     ALU_OP := "1011";
constant ALU_OP_SRL :     ALU_OP := "1100";
constant ALU_OP_MULT :    ALU_OP := "1101";
constant ALU_OP_TO_LO :   ALU_OP := "1110";
constant ALU_OP_TO_HI :   ALU_OP := "1111";

subtype ALU_SELECT is std_logic_vector(2 downto 0);
constant ALU_SELECT_ZERO			 : ALU_SELECT := "000";
constant ALU_SELECT_RS				 : ALU_SELECT := "001";
constant ALU_SELECT_RT				 : ALU_SELECT := "010";
constant ALU_SELECT_LO				 : ALU_SELECT := "011";
constant ALU_SELECT_HI				 : ALU_SELECT := "100";
constant ALU_SELECT_IMME_SIGN_EXTEND : ALU_SELECT := "101";
constant ALU_SELECT_IMME_ZERO_EXTEND : ALU_SELECT := "110";
constant ALU_SELECT_16	 			 : ALU_SELECT := "111";

subtype MEM_SELECT is std_logic_vector(1 downto 0);
constant MEM_SELECT_DISABLE			 : MEM_SELECT := "00";
constant MEM_SELECT_FROM_RS 		 : MEM_SELECT := "01";
constant MEM_SELECT_FROM_RS_BYTE 	 : MEM_SELECT := "10";

subtype ALIGN_TYPE is std_logic_vector(1 downto 0);
constant ALIGN_BYTE : ALIGN_TYPE := "01";
constant ALIGN_WORD : ALIGN_TYPE := "10";
constant ALIGN_QUAD : ALIGN_TYPE := "11";

subtype WB_SELECT is std_logic_vector(2 downto 0);
constant WB_SELECT_DISABLE					 : WB_SELECT := "000";
constant WB_SELECT_FROM_RS					 : WB_SELECT := "001";
constant WB_SELECT_FROM_ALU					 : WB_SELECT := "010";
constant WB_SELECT_FROM_RPC					 : WB_SELECT := "011";
constant WB_SELECT_FROM_MEM					 : WB_SELECT := "100";
constant WB_SELECT_FROM_MEMBYTE_SIGN_EXTEND  : WB_SELECT := "101";
constant WB_SELECT_FROM_MEMBYTE_ZERO_EXTEND  : WB_SELECT := "110";
constant WB_SELECT_FROM_MEMINT16_ZERO_EXTEND : WB_SELECT := "111";

subtype PHY_MEM_STATE is std_logic_vector(2 downto 0);
constant PHY_MEM_STATE_DISABLE : 	PHY_MEM_STATE := "000";
constant PHY_MEM_STATE_READ_RAM :   PHY_MEM_STATE := "001";
constant PHY_MEM_STATE_WRITE_RAM :  PHY_MEM_STATE := "010";
constant PHY_MEM_STATE_READ_FLASH1: PHY_MEM_STATE := "011";
constant PHY_MEM_STATE_READ_FLASH2: PHY_MEM_STATE := "100";
constant PHY_MEM_STATE_READ_SERIAL: PHY_MEM_STATE := "101";
constant PHY_MEM_STATE_WRITE_SERIAL:PHY_MEM_STATE := "110";

constant TLB_ENTRY_WIDTH :	integer := 63;
constant TLB_NUM_ENTRY : integer := 16;
constant TLB_INDEX_WIDTH : integer := 4;
constant TLB_WRITE_STRUCT_WIDTH : integer := TLB_ENTRY_WIDTH + TLB_INDEX_WIDTH;
subtype TLB_STRUCT is std_logic_vector(TLB_WRITE_STRUCT_WIDTH-1 downto 0);

constant VIRTUAL_SERIAL_DATA : std_logic_vector(31 downto 0) := x"bFD003F8";
constant VIRTUAL_SERIAL_STATUS : std_logic_vector(31 downto 0) := x"bFD003FC";
constant PHYSICAL_SERIAL_DATA : std_logic_vector(31 downto 0) := x"1FD003F8";
constant PHYSICAL_SERIAL_STATUS : std_logic_vector(31 downto 0) := x"1FD003FC";

constant NO_MEM_EXC : std_logic_vector(2 downto 0) := "000";
constant TLB_MODIFIED : std_logic_vector(2 downto 0) := "001";
constant TLB_L : std_logic_vector(2 downto 0) := "010";
constant TLB_S : std_logic_vector(2 downto 0) := "011";
constant ADE_L : std_logic_vector(2 downto 0) := "100";
constant ADE_S : std_logic_vector(2 downto 0) := "101";

constant INVALID_CONTENT : std_logic_vector(31 downto 0) := x"FFFFFFFF";

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

end com_define;

package body com_define is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end com_define;
