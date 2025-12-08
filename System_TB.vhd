library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity System_TB is
end System_TB;

architecture Behavioral of System_TB is
    
    component Car
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
    end component;
    
    component Key
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        Button     : in  STD_LOGIC;
        SPI_SCK    : out STD_LOGIC;
        SPI_MOSI   : out STD_LOGIC;
        SPI_SS     : out STD_LOGIC;
        Tx_Active  : out STD_LOGIC
    );
    end component;
    
    constant CLK_PERIOD : time := 10 ns;
    signal clk          : std_logic := '0';
    signal key_reset    : std_logic := '1';
    signal car_reset    : std_logic := '1';
    signal key_button   : std_logic := '0';
    
    signal key_sck      : std_logic;
    signal key_mosi     : std_logic;
    signal key_ss       : std_logic;
    signal key_tx_active: std_logic;
    signal car_miso     : std_logic;
    
    signal car_door     : std_logic;
    signal car_siren    : std_logic;
    
    signal test_done    : boolean := false;
    signal unlock_count : integer := 0;
    
begin
    
    clk_process: process
    begin
        while not test_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    UUT_Key: Key PORT MAP (
        clk => clk, 
        reset => key_reset,
        Button => key_button,
        SPI_SCK => key_sck, 
        SPI_MOSI => key_mosi, 
        SPI_SS => key_ss, 
        Tx_Active => key_tx_active
    );

    UUT_Car: Car PORT MAP (
        clk => clk, 
        reset => car_reset,
        SPI_SCLK => key_sck, 
        SPI_MOSI => key_mosi, 
        SPI_CS_N => key_ss, 
        SPI_MISO => car_miso,
        Door_Lock => car_door, 
        Siren => car_siren
    );
    
    stimulus: process
        
        procedure press_unlock_button is
        begin
            key_button <= '1';
            wait for 100 ns;
            key_button <= '0';
            
            wait until key_tx_active = '1' or test_done;
            wait until key_tx_active = '0' or test_done;
            
            wait for 5 us;
        end procedure;
        
        procedure lock_car is
        begin
            car_reset <= '1';
            wait for 200 ns;
            car_reset <= '0';
            wait for 500 ns;
        end procedure;

        procedure reset_key_counter is
        begin
            key_reset <= '1';
            wait for 500 ns;
            key_reset <= '0';
            wait for 1 us;
        end procedure;
    
        procedure run_test_cycle(cycle_num : in integer; expected_unlocked : in boolean; scenario_desc : in string) is
        begin
            press_unlock_button;
            
            if expected_unlocked then
                assert (car_door = '1' and car_siren = '0')
                    severity ERROR;
                
                if car_door = '1' then
                    unlock_count <= unlock_count + 1;
                end if;
            else
                assert (car_door = '0' and car_siren = '1')
                    severity ERROR;
            end if;
            
            wait for 3 us; 
        end procedure;
        
    begin
        reset_key_counter;
        car_reset <= '1';
        wait for 500 ns;
        car_reset <= '0';
        wait for 2 us; 
        
        run_test_cycle(1, TRUE, "Successful Authentication (Initial C)");
        lock_car;
        
        run_test_cycle(2, TRUE, "Successful Authentication (Sequential C)");
        lock_car;
        
        reset_key_counter;
        
        run_test_cycle(3, FALSE, "Replay Attack (Stale Counter)");
        
        lock_car;
        
        run_test_cycle(4, FALSE, "Recovery Attempt 1 (C=2, still stale)");
        lock_car;
        
        run_test_cycle(5, TRUE, "Recovery Attempt 2 (C=3, synchronized!)");
        lock_car;
        
        test_done <= true;
        wait;
        
    end process;

end Behavioral;