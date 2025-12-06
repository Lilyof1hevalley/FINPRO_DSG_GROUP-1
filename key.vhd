library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Key is
    Port ( 
           clk        : in  STD_LOGIC;
           reset      : in  STD_LOGIC;
           Button     : in  STD_LOGIC;
           SPI_SCK    : out STD_LOGIC;
           SPI_MOSI   : out STD_LOGIC;
           SPI_SS     : out STD_LOGIC;
           Tx_Active  : out STD_LOGIC
           );
end Key;

architecture Behavioral of Key is
    component OTP_Generator
    Port ( 
           Counter    : in  STD_LOGIC_VECTOR (31 downto 0);
           Secret_Key : in  STD_LOGIC_VECTOR (31 downto 0);
           OTP_Result : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;
    
    component SPI_Master
    Generic ( CLK_DIV : integer := 4 );
    Port (
        clk_sys : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        start   : in  STD_LOGIC;
        data_in : in  STD_LOGIC_VECTOR (31 downto 0);
        SCK     : out STD_LOGIC;
        SS      : out STD_LOGIC;
        MOSI    : out STD_LOGIC;
        busy    : out STD_LOGIC
    );
    end component;
    
    component Key_FSM
    Port ( 
           clk           : in  STD_LOGIC;
           reset         : in  STD_LOGIC;
           Button_Press  : in  STD_LOGIC;
           SPI_Busy      : in  STD_LOGIC;
           SPI_Start     : out STD_LOGIC;
           Packet_Select : out STD_LOGIC_VECTOR(1 downto 0);
           Inc_Counter   : out STD_LOGIC
    );
    end component;
    
    --remote config
    constant MY_USER_ID    : std_logic_vector(1 downto 0)  := "00";
    constant MY_SECRET_KEY : std_logic_vector(31 downto 0) := x"11111111";
    
    signal r_counter      : std_logic_vector(31 downto 0);
    signal w_otp_result   : std_logic_vector(31 downto 0);
    signal fsm_start_spi  : std_logic;
    signal fsm_pkt_sel    : std_logic_vector(1 downto 0);
    signal fsm_inc_cnt    : std_logic;
    signal spi_is_busy    : std_logic;
    signal spi_data_mux   : std_logic_vector(31 downto 0);
    
    --button signal
    signal btn_sync       : std_logic_vector(2 downto 0) := "000";
    signal btn_stable     : std_logic := '0';
begin
    Tx_Active <= spi_is_busy;
    
    --button signal process
    process(clk)
    begin
        if rising_edge(clk) then
            btn_sync <= btn_sync(1 downto 0) & Button;
            if btn_sync = "111" then
                btn_stable <= '1';
            elsif btn_sync = "000" then
                btn_stable <= '0';
            end if;
        end if;
    end process;
    
    --counter
    process(clk, reset)
    begin
        if reset = '1' then
            r_counter <= x"00000001";  --start from here from 1
        elsif rising_edge(clk) then
            if fsm_inc_cnt = '1' then
                r_counter <= std_logic_vector(unsigned(r_counter) + 1);
            end if;
        end if;
    end process;
    

	--bellow are all the instantiation:
    --otp gen instantiation
    Gen_Unit: OTP_Generator PORT MAP (
        Counter    => r_counter,
        Secret_Key => MY_SECRET_KEY,
        OTP_Result => w_otp_result
    );
    
    --data multiplexer
    process(fsm_pkt_sel, r_counter, w_otp_result)
    begin
        case fsm_pkt_sel is
            when "00" =>
                spi_data_mux <= x"0000000" & "00" & MY_USER_ID;
            when "01" =>
                spi_data_mux <= r_counter;
            when "10" =>
                spi_data_mux <= w_otp_result;
            when others =>
                spi_data_mux <= (others => '0');
        end case;
    end process;
    
    --key fsm
    Control_Unit: Key_FSM PORT MAP (
        clk           => clk,
        reset         => reset,
        Button_Press  => btn_stable,  
        SPI_Busy      => spi_is_busy,
        SPI_Start     => fsm_start_spi,
        Packet_Select => fsm_pkt_sel,
        Inc_Counter   => fsm_inc_cnt
    );
    
    --spi master instantiation
    SPI_Tx: SPI_Master 
    GENERIC MAP ( CLK_DIV => 4 )
    PORT MAP (
        clk_sys => clk,
        rst     => reset,
        start   => fsm_start_spi,
        data_in => spi_data_mux,
        SCK     => SPI_SCK,
        SS      => SPI_SS,
        MOSI    => SPI_MOSI,
        busy    => spi_is_busy
    );
end Behavioral;