library verilog;
use verilog.vl_types.all;
entity async_receiver is
    generic(
        ClkFrequency    : integer := 25000000;
        Baud            : integer := 38400;
        Oversampling    : integer := 16
    );
    port(
        clk             : in     vl_logic;
        RxD             : in     vl_logic;
        RxD_data_ready  : out    vl_logic;
        RxD_data        : out    vl_logic_vector(7 downto 0);
        RxD_idle        : out    vl_logic;
        RxD_endofpacket : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of ClkFrequency : constant is 1;
    attribute mti_svvh_generic_type of Baud : constant is 1;
    attribute mti_svvh_generic_type of Oversampling : constant is 1;
end async_receiver;
