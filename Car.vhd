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
    
    component Car_Database
    Port (
        clk : in std_logic;
        rst : in std_logic;
        lookup_id : in std_logic_vector(7 downto 0);
        lookup_en : in std_logic;
        key_found : out std_logic;
        stored_key : out std_logic_vector(31 downto 0);
        stored_counter : out std_logic_vector(7 downto 0);
        update_en : in std_logic;
        update_id : in std_logic_vector(7 downto 0);
        update_counter : in std_logic_vector(7 downto 0)
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
           Update_DB       : out STD_LOGIC
    );
    end component;

    signal reset_n          : std_logic;
    signal spi_data_out     : std_logic_vector(31 downto 0);
    signal spi_new_data     : std_logic;
    signal Reg_User_ID      : std_logic_vector(7 downto 0) := (others => '0');
    signal Reg_Counter      : std_logic_vector(31 downto 0) := (others => '0');
    signal Reg_OTP_Code     : std_logic_vector(31 downto 0) := (others => '0');
    signal Packet_State     : integer range 0 to 3 := 0;
    signal db_lookup_en     : std_logic := '0';
    signal db_key_found     : std_logic;
    signal db_stored_key    : std_logic_vector(31 downto 0);
    signal db_stored_counter: std_logic_vector(7 downto 0);
    signal db_update_en     : std_logic := '0';
    signal db_update_counter: std_logic_vector(7 downto 0);
    signal Expected_OTP     : std_logic_vector(31 downto 0);
    signal Internal_Trigger : std_logic := '0';
    signal Match_Flag       : std_logic;
    signal Counter_Valid    : std_logic;
    signal Update_Counter   : std_logic;
    
    constant SYNC_WINDOW : integer := 10;
    
begin
    
    reset_n <= not reset;
    
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
    
    CNT_DB: Car_Database PORT MAP (
        clk => clk,
        rst => reset,
        lookup_id => Reg_User_ID,
        lookup_en => db_lookup_en,
        key_found => db_key_found,
        stored_key => db_stored_key,
        stored_counter => db_stored_counter,
        update_en => db_update_en,
        update_id => Reg_User_ID,
        update_counter => db_update_counter
    );
    
    Calc_Unit: OTP_Generator PORT MAP (
        Counter => Reg_Counter,
        Secret_Key => db_stored_key,
        OTP_Result => Expected_OTP
    );
    
    Control_Unit: Car_FSM PORT MAP (
        clk => clk,
        reset => reset,
        Remote_Trigger => Internal_Trigger,
        Code_Is_Correct => Match_Flag,
        Door_Open => Door_Lock,
        Alarm_Siren => Siren,
        Check_Enable => open,
        Update_DB => Update_Counter
    );
    
    process(clk, reset)
        variable trigger_counter : integer range 0 to 5 := 0;
    begin
        if reset = '1' then
            Packet_State <= 0;
            Internal_Trigger <= '0';
            Reg_User_ID <= (others => '0');
            Reg_Counter <= (others => '0');
            Reg_OTP_Code <= (others => '0');
            trigger_counter := 0;
        elsif rising_edge(clk) then
            Internal_Trigger <= '0';
            if trigger_counter > 0 then
                trigger_counter := trigger_counter - 1;
                if trigger_counter = 0 then
                    Internal_Trigger <= '1';
                end if;
            end if;

            if spi_new_data = '1' then
                case Packet_State is
                    when 0 =>
                        Reg_User_ID <= spi_data_out(7 downto 0);
                        Packet_State <= 1;
                    when 1 =>
                        Reg_Counter <= spi_data_out;
                        Packet_State <= 2;
                    when 2 =>
                        Reg_OTP_Code <= spi_data_out;
                        Packet_State <= 0;
                        trigger_counter := 4;
                    when others =>
                        Packet_State <= 0;
                end case;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if spi_new_data = '1' and Packet_State = 0 then
                db_lookup_en <= '1';
            elsif spi_new_data = '1' and Packet_State = 1 then
                db_lookup_en <= '1';
            else
                db_lookup_en <= '0';
            end if;
            
            if Update_Counter = '1' then
                db_update_en <= '1';
            else
                db_update_en <= '0';
            end if;
        end if;
    end process;
    
    process(Reg_Counter, db_stored_counter)
        variable recv_cnt : unsigned(7 downto 0);
        variable stored_cnt : unsigned(7 downto 0);
        variable upper_limit : unsigned(7 downto 0);
    begin
        recv_cnt := unsigned(Reg_Counter(7 downto 0));
        stored_cnt := unsigned(db_stored_counter);
        
        if stored_cnt <= 255 - SYNC_WINDOW then
            upper_limit := stored_cnt + SYNC_WINDOW;
        else
            upper_limit := to_unsigned(255, 8);
        end if;
        
        if (recv_cnt >= stored_cnt) and (recv_cnt <= upper_limit) then
            Counter_Valid <= '1';
        else
            Counter_Valid <= '0';
        end if;
    end process;
    
    process(Reg_OTP_Code, Expected_OTP, Counter_Valid, db_key_found)
    begin
        if (Reg_OTP_Code = Expected_OTP) and (Counter_Valid = '1') and (db_key_found = '1') then
            Match_Flag <= '1';
        else
            Match_Flag <= '0';
        end if;
    end process;
    
    db_update_counter <= std_logic_vector(unsigned(Reg_Counter(7 downto 0)) + 1);

    
end Behavioral;
