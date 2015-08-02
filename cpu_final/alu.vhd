library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.com_define.ALL;

entity alu is
	port(
		clk, rst, pause: in std_logic;
		status : in INT3;
		
		alu_srcA, alu_srcB : in INT32;
		alu_op : in ALU_OP;
		alu_value, lo_value, hi_value : out INT32
		
	);
end alu;

architecture bhv of alu is

signal s_alu_value : INT32 ;
signal s_lo_hi_value : std_logic_vector(63 downto 0) ;

begin
	alu_value <= s_alu_value ;
	lo_value <= s_lo_hi_value(31 downto 0) ;
	hi_value <= s_lo_hi_value(63 downto 32) ;
	
	process(rst, clk)
	begin
		if rst = '0' then
			s_alu_value <= (others => '0') ;
			s_lo_hi_value <= (others => '0') ;
		elsif clk'event and clk = '1' and status = "001" and pause = '0' then
			-- generate alu_value
			case alu_op is
				when ALU_OP_ADD => 
					s_alu_value <= alu_srcA + alu_srcB ;
				when ALU_OP_CMP =>
					if signed(alu_srcA) < signed(alu_srcB) then
						s_alu_value <= INT32_ONE;
					else
						s_alu_value <= INT32_ZERO;
					end if;
				when ALU_OP_CMPU =>
					if unsigned(alu_srcA) < unsigned(alu_srcB) then
						s_alu_value <= INT32_ONE;
					else
						s_alu_value <= INT32_ZERO;
					end if;
				when ALU_OP_SUBU =>
					s_alu_value <= alu_srcA - alu_srcB ;
				when ALU_OP_SRCA =>
					s_alu_value <= alu_srcA ;
				when ALU_OP_AND =>
					s_alu_value <= alu_srcA and alu_srcB ;
				when ALU_OP_NOR =>
					s_alu_value <= alu_srcA nor alu_srcB ;
				when ALU_OP_OR =>
					s_alu_value <= alu_srcA or alu_srcB ;
				when ALU_OP_XOR =>
					s_alu_value <= alu_srcA xor alu_srcB ;
				when ALU_OP_SLL =>
					s_alu_value <= to_stdlogicvector(to_bitvector(alu_srcA) sll to_integer(unsigned(alu_srcB)));
				when ALU_OP_SRA =>
					s_alu_value <= to_stdlogicvector(to_bitvector(alu_srcA) sra to_integer(unsigned(alu_srcB)));
				when ALU_OP_SRL =>
					s_alu_value <= to_stdlogicvector(to_bitvector(alu_srcA) srl to_integer(unsigned(alu_srcB)));
				when others =>
					s_alu_value <= (others => '0');
			end case;
		
			-- generate alu_lo_value, alu_hi_value
			case alu_op is
				when ALU_OP_MULT =>
					s_lo_hi_value <= std_logic_vector(signed(alu_srcA) * signed(alu_srcB));
				when ALU_OP_TO_LO =>
					s_lo_hi_value(31 downto 0) <= alu_srcA ;
					s_lo_hi_value(63 downto 32) <= (others => '0') ;
				when ALU_OP_TO_HI =>
					s_lo_hi_value(31 downto 0) <= (others => '0') ;
					s_lo_hi_value(63 downto 32) <= alu_srcA ;
				when others =>
					s_lo_hi_value <= (others => '0') ;
			end case;
			
		end if ;
		
	end process;
		
end bhv;



