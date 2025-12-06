library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Car is
    Port ( 
           clk            : in  STD_LOGIC;
           reset          : in  STD_LOGIC;
           SPI_SCLK       : in  STD_LOGIC;
           SPI_MOSI       : in  STD_LOGIC;
           SPI_CS_N       : in  STD_LOGIC;
           SPI_MISO       : out STD_LOGIC;
           Door_Lock      : out STD_LOGIC;
           Siren          : out STD_LOGIC
           );
end Car;

architecture Behavioral of Car is
    component SPI_Slave
    port (
        CLK_IN      : in  std_logic;
        RESET_N     : in  std_logic;
        SPI_SCLK    : in  std_logic;
        SPI_MOSI    : in  std_logic;
        SPI_CS_N    : in  std_logic;
        DATA_IN     : in  std_logic_vector(31 downto 0);
        DATA_OUT    : out std_logic_vector(31 downto 0);
        NEW_DATA    : out std_logic;
        SPI_MISO_OUT: out std_logic
    );
    end component;
    
    component Key_Database
    Port ( 
           clk            : in  STD_LOGIC;
           User_ID        : in  STD_LOGIC_VECTOR (1 downto 0);
           Secret_Key_Out : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;
    
    -- NEW COMPONENT
    component Counter_Database
    Port ( 
           clk          : in  STD_LOGIC;
           reset        : in  STD_LOGIC;
           User_ID      : in  STD_LOGIC_VECTOR (1 downto 0);
           Last_Cnt_Out : out STD_LOGIC_VECTOR (31 downto 0);
           Write_En     : in  STD_LOGIC;
           New_Cnt_In   : in  STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;
    
    component OTP_Generator
    Port ( 
           Counter    : in  STD_LOGIC_VECTOR (31 downto 0);
           Secret_Key : in  STD_LOGIC_VECTOR (31 downto 0);
           OTP_Result : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;
    
    component Car_FSM
    Port ( 
           clk             : in  STD_LOGIC;
           reset           : in  STD_LOGIC;
           Remote_Trigger  : in  STD_LOGIC;
           Code_Is_Correct : in  STD_LOGIC;
           Door_Open       : out STD_LOGIC;
           Alarm_Siren     : out STD_LOGIC;
           Check_Enable    : out STD_LOGIC;
           Update_DB       : out STD_LOGIC  -- NEW
    );
    end component;
    
    signal reset_n        : std_logic;
    signal spi_data_out   : std_logic_vector(31 downto 0);
    signal spi_new_data   : std_logic;
    signal Reg_User_ID    : std_logic_vector(1 downto 0);
    signal Reg_Counter    : std_logic_vector(31 downto 0);
    signal Reg_OTP_Code   : std_logic_vector(31 downto 0);
    signal Packet_State   : integer range 0 to 3 := 0;
    signal Internal_Trigger : std_logic := '0';
    signal Internal_Key   : std_logic_vector(31 downto 0);
    signal Expected_OTP   : std_logic_vector(31 downto 0);
    signal Match_Flag     : std_logic;
    signal FSM_Enable     : std_logic;
    
    -- NEW SIGNALS untuk Counter Database
    signal Last_Counter   : std_logic_vector(31 downto 0);
    signal Counter_Valid  : std_logic;
    signal Update_Counter : std_logic;
    
    -- Sync window untuk toleransi counter drift
    constant SYNC_WINDOW : integer := 10;
begin
    reset_n <= not reset;
    
    -- SPI Slave Instance
    SPI_Unit: SPI_Slave PORT MAP (
        CLK_IN       => clk,
        RESET_N      => reset_n,
        SPI_SCLK     => SPI_SCLK,
        SPI_MOSI     => SPI_MOSI,
        SPI_CS_N     => SPI_CS_N,
        DATA_IN      => x"00000000",
        DATA_OUT     => spi_data_out,
        NEW_DATA     => spi_new_data,
        SPI_MISO_OUT => SPI_MISO
    );
    
    -- Data Assembly Process
    process(clk, reset)
    begin
        if reset = '1' then
            Packet_State <= 0;
            Internal_Trigger <= '0';
            Reg_User_ID <= (others => '0');
            Reg_Counter <= (others => '0');
            Reg_OTP_Code <= (others => '0');
        elsif rising_edge(clk) then
            Internal_Trigger <= '0';
            if spi_new_data = '1' then
                case Packet_State is
                    when 0 =>
                        Reg_User_ID <= spi_data_out(1 downto 0);
                        Packet_State <= 1;
                    when 1 =>
                        Reg_Counter <= spi_data_out;
                        Packet_State <= 2;
                    when 2 =>
                        Reg_OTP_Code <= spi_data_out;
                        Packet_State <= 0;
                        Internal_Trigger <= '1';
                    when others =>
                        Packet_State <= 0;
                end case;
            end if;
        end if;
    end process;
    
    -- Key Database Instance
    DB_Unit: Key_Database PORT MAP (
        clk => clk,
        User_ID => Reg_User_ID,
        Secret_Key_Out => Internal_Key
    );
    
    -- NEW: Counter Database Instance
    CNT_DB: Counter_Database PORT MAP (
        clk => clk,
        reset => reset,
        User_ID => Reg_User_ID,
        Last_Cnt_Out => Last_Counter,
        Write_En => Update_Counter,
        New_Cnt_In => Reg_Counter
    );
    
    -- OTP Generator Instance
    Calc_Unit: OTP_Generator PORT MAP (
        Counter => Reg_Counter,
        Secret_Key => Internal_Key,
        OTP_Result => Expected_OTP
    );
    
    -- NEW: Counter Validation Logic (Anti-Replay Attack)
    process(Reg_Counter, Last_Counter)
    begin
        if (unsigned(Reg_Counter) > unsigned(Last_Counter)) and
           (unsigned(Reg_Counter) <= unsigned(Last_Counter) + SYNC_WINDOW) then
            Counter_Valid <= '1';
        else
            Counter_Valid <= '0';
        end if;
    end process;
    
    -- UPDATED: Match Flag dengan Counter Validation
    process(Reg_OTP_Code, Expected_OTP, Counter_Valid)
    begin
        if (Reg_OTP_Code = Expected_OTP) and (Counter_Valid = '1') then
            Match_Flag <= '1';
        else
            Match_Flag <= '0';
        end if;
    end process;
    
    -- Car FSM Instance
    Control_Unit: Car_FSM PORT MAP (
        clk => clk,
        reset => reset,
        Remote_Trigger => Internal_Trigger,
        Code_Is_Correct => Match_Flag,
        Door_Open => Door_Lock,
        Alarm_Siren => Siren,
        Check_Enable => FSM_Enable,
        Update_DB => Update_Counter  -- NEW: Connect update signal
    );
end Behavioral;
