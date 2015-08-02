library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.com_define.ALL;
use work.rom.ALL;

entity phy_mem is
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
end phy_mem;

architecture Behavioral of phy_mem is
component ram
    Port(clock: in std_logic; reset: in std_logic; ope_addr: in std_logic_vector(19 downto 0); write_data: in std_logic_vector(31 downto 0); read_data: out std_logic_vector(31 downto 0);ope_we: in std_logic; ope_ce1: in std_logic; ope_ce2: in std_logic; baseram_addr: out std_logic_vector(19 downto 0); baseram_data: inout std_logic_vector(31 downto 0);baseram_ce: out std_logic; baseram_oe: out std_logic; baseram_we: out std_logic; extrram_addr: out std_logic_vector(19 downto 0); extrram_data: inout std_logic_vector(31 downto 0); extrram_ce: out std_logic; extrram_oe: out std_logic; extrram_we: out std_logic);
end component;

signal ram_ope_addr: std_logic_vector(19 downto 0);
signal ram_write_data: std_logic_vector(31 downto 0);
signal ram_read_data: std_logic_vector(31 downto 0);
signal ram_ope_we: std_logic;
signal ram_ope_ce1: std_logic := '0';
signal ram_ope_ce2: std_logic := '0';

component flash is
    Port ( clock : in  STD_LOGIC; addr : in  STD_LOGIC_VECTOR (21 downto 0); data_in : in STD_LOGIC_VECTOR (15 downto 0);data_out : out  STD_LOGIC_VECTOR (15 downto 0);read_enable: in std_logic;write_enable: in std_logic;erase_enable: in std_logic;flash_addr : out  STD_LOGIC_VECTOR (22 downto 0);flash_data : inout  STD_LOGIC_VECTOR (15 downto 0);flash_control_ce0: out std_logic;flash_control_ce1: out std_logic;flash_control_ce2: out std_logic;flash_control_byte: out std_logic;flash_control_vpen: out std_logic;flash_control_rp: out std_logic;flash_control_oe: out std_logic;flash_control_we: out std_logic);    
end component;

signal flash_read_signal: std_logic := '0';
signal flash_read_data: std_logic_vector(15 downto 0);
constant flash_write_data: std_logic_vector(15 downto 0) := (others => '0'); -- not supported
signal flash_ope_addr: std_logic_vector(21 downto 0);

component async_receiver
    port(clk: in std_logic; RxD: in std_logic; RxD_data_ready: out std_logic; RxD_data: out std_logic_vector(7 downto 0));
end component;

signal serialport_receive_signal: std_logic := '0';
signal serialport_receive_data: std_logic_vector(7 downto 0);
signal serialport_data_latch: std_logic_vector(7 downto 0);

component async_transmitter
    port(clk: in std_logic; TxD_start: in std_logic; TxD_data: in std_logic_vector(7 downto 0); TxD: out std_logic; TxD_busy: out std_logic);
end component;

signal serialport_transmit_signal : std_logic := '0';
signal serialport_transmit_data : std_logic_vector(7 downto 0);
signal serialport_transmit_busy : std_logic := '0';



begin
    u3: async_receiver port map(clk => clk_f, RxD => serialport_rxd, RxD_data_ready => serialport_receive_signal, RxD_data => serialport_receive_data);  
    
    u4: async_transmitter port map(clk => clk_f, Txd => serialport_txd, TxD_start => serialport_transmit_signal,TxD_data => serialport_transmit_data, Txd_busy => serialport_transmit_busy);
    
    u2: flash port map(clock => clk_f, addr => flash_ope_addr, data_in => flash_write_data, data_out => flash_read_data, 
                      flash_addr => flash_addr, flash_data => flash_data,
                      read_enable => flash_read_signal, write_enable => '0', erase_enable => '0',
                      flash_control_ce0 => flash_control_ce0, flash_control_ce1 => flash_control_ce1,
                      flash_control_ce2 => flash_control_ce2, flash_control_byte => flash_control_byte,
                      flash_control_vpen => flash_control_vpen, flash_control_rp => flash_control_rp,
                      flash_control_oe => flash_control_oe, flash_control_we => flash_control_we);
    u1: ram port map(clock => clk_f, reset => '1', ope_ce1 => ram_ope_ce1, ope_ce2 => ram_ope_ce2,
                     ope_addr => ram_ope_addr, write_data => ram_write_data, 
                     read_data => ram_read_data, ope_we => ram_ope_we,
                     baseram_addr => baseram_addr, baseram_data => baseram_data, baseram_ce => baseram_ce, baseram_oe => baseram_oe, baseram_we => baseram_we,
                     extrram_addr => extrram_addr, extrram_data => extrram_data, extrram_ce => extrram_ce, extrram_oe => extrram_oe, extrram_we => extrram_we);
    
    process (clk) 
        variable v_state : PHY_MEM_STATE := PHY_MEM_STATE_DISABLE;
    begin
        if (clk'event and clk = '1') then
            -- check signal from serial port
            if (serialport_receive_signal = '1') then
                -- if have data incoming, latch it
                serialport_data_latch <= serialport_receive_data;
                serialport_data_ready <= '1';
            end if;
            if v_state = PHY_MEM_STATE_WRITE_SERIAL then
            	serialport_transmit_signal <= '0';
                if (serialport_transmit_busy = '0') then
                    v_state := PHY_MEM_STATE_DISABLE;
                    busy <= '0';
                end if;
            else
		        case (status) is
		            when "000" =>
		                -- read flash
		                if (read_enable = '1' and addr(23 downto 22) = "00") then
		                    flash_ope_addr <= addr(21 downto 0);
		                    flash_read_signal <= '1';
		                    v_state := PHY_MEM_STATE_READ_FLASH1;
		                -- write ram
		                elsif (write_enable = '1' and addr(23 downto 22) = "01") then
		                    ram_ope_addr <= addr(19 downto 0);
		                    ram_write_data <= data_in;
		                    ram_ope_we <= '0';
		                    ram_ope_ce1 <= not addr(20);
		                    ram_ope_ce2 <= addr(20);
		                    v_state := PHY_MEM_STATE_WRITE_RAM;
		                -- read ram
		                elsif (read_enable = '1' and addr(23 downto 22) = "01") then
		                    ram_ope_addr <= addr(19 downto 0);
		                    ram_ope_we <= '1';
		                    ram_ope_ce1 <= not addr(20);
		                    ram_ope_ce2 <= addr(20);
		                    v_state := PHY_MEM_STATE_READ_RAM;
		                -- read serial port
		                elsif (read_enable = '1' and addr(23 downto 22) = "10") then
		                    data_out <= X"000000" & serialport_data_latch;
		                    serialport_data_ready <= '0';
		                    v_state := PHY_MEM_STATE_READ_SERIAL;
		                -- write serial port
		                elsif (write_enable = '1' and addr(23 downto 22) = "10") then
		                    serialport_transmit_signal <= '1';
		                    serialport_transmit_data <= data_in(7 downto 0);
		                    v_state := PHY_MEM_STATE_WRITE_SERIAL;
		                -- read rom
		                elsif (read_enable = '1' and addr(23 downto 22) = "11") then
		                    data_out <= boot_rom(to_integer(unsigned(addr(21 downto 0))));
		                else
		                    v_state := PHY_MEM_STATE_DISABLE;
							data_out <= (others => '0');
		                    flash_read_signal <= '0';
		                end if;
		            when "001" =>
		            	if v_state = PHY_MEM_STATE_DISABLE then
		            		busy <= '0';
		            	else
		            		busy <= '1';
		            		if v_state = PHY_MEM_STATE_WRITE_RAM or v_state = PHY_MEM_STATE_READ_RAM then
		            			ram_ope_ce1 <= '0';
		                		ram_ope_ce2 <= '0';
		                	end if;
		            	end if;
		            when "101" =>
		            	if v_state = PHY_MEM_STATE_READ_FLASH2 then
		                	data_out <= X"0000" & flash_read_data;
		                	v_state := PHY_MEM_STATE_DISABLE;
		                	busy <= '0';
		               	elsif v_state = PHY_MEM_STATE_READ_RAM then
		                	data_out <= ram_read_data;
		                	v_state := PHY_MEM_STATE_DISABLE;
		                	busy <= '0';
		                elsif v_state = PHY_MEM_STATE_WRITE_RAM then
		                	v_state := PHY_MEM_STATE_DISABLE;
		                	busy <= '0';
		                end if;
		            when "110" =>
		            	if v_state = PHY_MEM_STATE_READ_FLASH1 then
		                	flash_read_signal <= '0';
		                	v_state := PHY_MEM_STATE_READ_FLASH2;
		                end if;
		            when others =>
		       			null;
		        end case;
            end if;
        end if;
    end process;
end Behavioral;

