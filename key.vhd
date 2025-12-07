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

architecture Hybrid of Key is

--component declarations (structural part):
    --button debouncer comp
    
    component Button_Debouncer is
        Port(
            clk     : in std_logic;
            btn_in  : in std_logic;
            btn_out : out std_logic
        );
    end component;
    
    --counter increment comp
    component Counter_Inc is
        Port (
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            enable   : in  STD_LOGIC;
            inc      : in  STD_LOGIC; --increment pulse
            load     : in  STD_LOGIC; --load new value
            data_in  : in  STD_LOGIC_VECTOR(31 downto 0);
            count    : out STD_LOGIC_VECTOR(31 downto 0);
            overflow : out STD_LOGIC  --overflow indicator
        );
    end component;
    
    --otp gen comp
    component OTP_Generator is
        Port ( 
            Counter    : in  STD_LOGIC_VECTOR (31 downto 0);
            Secret_Key : in  STD_LOGIC_VECTOR (31 downto 0);
            OTP_Result : out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;
    
    --key fsm comp
    component Key_FSM is
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
    
    --spi master comp
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
    
--signal & constants (behavioral):
    --remote configuration
    constant MY_USER_ID    : std_logic_vector(1 downto 0)  := "10";      -- fixing this to match the ID on the database this case was  2 (matches Car DB)
    constant MY_SECRET_KEY : std_logic_vector(31 downto 0) := x"0000000B"; -- Key = 11(matches Car DB)
    
    --the internal signals
    signal btn_debounced   : std_logic;
    signal counter_value   : std_logic_vector(31 downto 0);
    signal otp_value       : std_logic_vector(31 downto 0);
    signal fsm_start_spi   : std_logic;
    signal fsm_pkt_sel     : std_logic_vector(1 downto 0);
    signal fsm_inc_cnt     : std_logic;
    signal spi_is_busy     : std_logic;
    signal spi_data_mux    : std_logic_vector(31 downto 0);
    
    --the counter control signals
    signal counter_enable  : std_logic := '1'; --always enabed
    signal counter_load    : std_logic := '0'; --not loading
    signal counter_data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal counter_overflow: std_logic; --not used
    
begin

--output assignment (which also behavioral)
    Tx_Active <= spi_is_busy;

--component instantiations (structural):

    --button debouncer instants
    DEBOUNCER: Button_Debouncer
    port map (
        clk     => clk,
        btn_in  => Button,
        btn_out => btn_debounced
    );
    
    --counter increment instants
    COUNTER: Counter_Inc
    port map (
        clk      => clk,
        reset    => reset,
        enable   => counter_enable,
        inc      => fsm_inc_cnt,
        load     => counter_load,
        data_in  => counter_data_in,
        count    => counter_value,
        overflow => counter_overflow
    );
    
    --otp gen instants
    OTP_GEN: OTP_Generator
    port map (
        Counter    => counter_value,
        Secret_Key => MY_SECRET_KEY,
        OTP_Result => otp_value
    );
    
    --key fsm instants
    FSM: Key_FSM
    port map (
        clk           => clk,
        reset         => reset,
        Button_Press  => btn_debounced,
        SPI_Busy      => spi_is_busy,
        SPI_Start     => fsm_start_spi,
        Packet_Select => fsm_pkt_sel,
        Inc_Counter   => fsm_inc_cnt
    );
    
    --spi master instants
    SPI: SPI_Master
    generic map ( 
        CLK_DIV => 4 
    )
    port map (
        clk_sys => clk,
        rst     => reset,
        start   => fsm_start_spi,
        data_in => spi_data_mux,
        SCK     => SPI_SCK,
        SS      => SPI_SS,
        MOSI    => SPI_MOSI,
        busy    => spi_is_busy
    );
    
--behavioral processes
--this is to select which packet to send based on fsm state
--00, send user id, 01 send counter, 10 send otp, 11 unsed
    process(fsm_pkt_sel, counter_value, otp_value)
    begin
        case fsm_pkt_sel is
            when "00" =>  -- Packet 1: User ID
                spi_data_mux <= x"000000" & "000000" & MY_USER_ID;
            when "01" =>  -- Packet 2: Counter
                spi_data_mux <= counter_value;
            when "10" =>  -- Packet 3: OTP
                spi_data_mux <= otp_value;
            when others =>
                spi_data_mux <= (others => '0');
        end case;
    end process;
    
--overflow monitoring
    process(clk)
    begin
        if rising_edge(clk) then
            if counter_overflow = '1' then
                null;
            end if;
        end if;
    end process;
    
end Hybrid;

--basically accepting "signal" outside from button debouncer to get the btn_debounced		
--btn_debounced was sent to key fsm that controls the sequence (choosing data packet via fsm pkt selector)		
--obtaining data from the counter/otp to be sent to the spi master, that later will sent to transmission active indicator