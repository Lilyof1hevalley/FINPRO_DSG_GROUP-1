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
            inc      : in  STD_LOGIC;      --increment pulse
            load     : in  STD_LOGIC;      --load new value
            data_in  : in  STD_LOGIC_VECTOR(31 downto 0);
            count    : out STD_LOGIC_VECTOR(31 downto 0);
            overflow : out STD_LOGIC       --overflow indicator
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
    constant MY_USER_ID    : std_logic_vector(1 downto 0)  := "00";
    constant MY_SECRET_KEY : std_logic_vector(31 downto 0) := x"11111111";
    
    --the internal signal
    signal btn_debounced   : std_logic;                    --from Button_Debouncer
    signal counter_value   : std_logic_vector(31 downto 0);--from Counter_Inc
    signal otp_value       : std_logic_vector(31 downto 0);--from OTP_Generator
    signal fsm_start_spi   : std_logic;                    --from Key_FSM
    signal fsm_pkt_sel     : std_logic_vector(1 downto 0); --from Key_FSM
    signal fsm_inc_cnt     : std_logic;                    --from Key_FSM
    signal spi_is_busy     : std_logic;                    --from SPI_Master
    signal spi_data_mux    : std_logic_vector(31 downto 0);--to SPI_Master
    
    --counter control signals (for the counter increment)
    signal counter_enable  : std_logic := '1';             --always enabled
    signal counter_load    : std_logic := '0';             --not loading
    signal counter_data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal counter_overflow: std_logic;                    --not used
    
begin

--output assignment (which also behavioral)
    Tx_Active <= spi_is_busy;
    
--component instantiations (structural)
    
    --button debouncer
    BUTTON_DEBOUNCER: Button_Debouncer
    port map (
        clk     => clk,
        btn_in  => Button,
        btn_out => btn_debounced
    );
    
    --counter increment
    COUNTER: Counter_Inc
    port map (
        clk      => clk,
        reset    => reset,
        enable   => counter_enable,
        inc      => fsm_inc_cnt,      --increment from FSM
        load     => counter_load,     --not used 
        data_in  => counter_data_in,  --not used 
        count    => counter_value,    --counter value to otp & mux
        overflow => counter_overflow  --not used
    );
    
    --otp gen instanttiations
    OTP_GENERATOR: OTP_Generator
    port map (
        Counter    => counter_value,
        Secret_Key => MY_SECRET_KEY,
        OTP_Result => otp_value
    );
    
    --key fsm instantiations
    KEY_FSM: Key_FSM
    port map (
        clk           => clk,
        reset         => reset,
        Button_Press  => btn_debounced,   --using debounced button
        SPI_Busy      => spi_is_busy,
        SPI_Start     => fsm_start_spi,
        Packet_Select => fsm_pkt_sel,
        Inc_Counter   => fsm_inc_cnt
    );
    
    --spi master instantiations
    SPI_MASTER: SPI_Master
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
    --this is to selects which packet to send based on FSM state
    --if its 00, then it sends user id, if its 01, sends counter, if its 10 sends
    --otp, while 11 is unused
    
    process(fsm_pkt_sel, counter_value, otp_value)
    begin
        case fsm_pkt_sel is
            when "00" => spi_data_mux <= x"0000000" & "00" & MY_USER_ID;
            when "01" => spi_data_mux <= counter_value;
            when "10" => spi_data_mux <= otp_value;
            when others => spi_data_mux <= (others => '0');
        end case;
    end process;
    
end Hybrid;

--basically accepting "signal" outside from button debouncer to get the btn_debounced
--btn_debounced was sent to key fsm that controls the sequence (choosing data packet via fsm pkt selector)
--obtaining data from the counter/otp to be sent to the spi master, that later will sent to transmission active indicator
