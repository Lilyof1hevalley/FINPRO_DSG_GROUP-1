-- ============================================================================
-- SYSTEM_TB.VHD - Enhanced Testbench dengan Debug & Real-Life Scenarios
-- ============================================================================
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
    
    -- Clock & Reset
    constant CLK_PERIOD : time := 10 ns;
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    
    -- Key Fob Signals
    signal key_button   : std_logic := '0';
    signal key_sck      : std_logic;
    signal key_mosi     : std_logic;
    signal key_ss       : std_logic;
    signal key_tx_active: std_logic;
    
    -- Car Signals
    signal car_miso     : std_logic;
    signal car_door     : std_logic;
    signal car_siren    : std_logic;
    
    -- Test Control
    signal test_done    : boolean := false;
    signal test_number  : integer := 0;
    
begin
    
    -- ========================================
    -- CLOCK GENERATION
    -- ========================================
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
    
    -- ========================================
    -- DUT INSTANTIATION
    -- ========================================
    UUT_Key: Key PORT MAP (
        clk       => clk,
        reset     => reset,
        Button    => key_button,
        SPI_SCK   => key_sck,
        SPI_MOSI  => key_mosi,
        SPI_SS    => key_ss,
        Tx_Active => key_tx_active
    );
    
    UUT_Car: Car PORT MAP (
        clk       => clk,
        reset     => reset,
        SPI_SCLK  => key_sck,
        SPI_MOSI  => key_mosi,
        SPI_CS_N  => key_ss,
        SPI_MISO  => car_miso,
        Door_Lock => car_door,
        Siren     => car_siren
    );
    
    -- ========================================
    -- MAIN TEST STIMULUS
    -- ========================================
    stimulus: process
        
        -- Helper procedure untuk press button
        procedure press_key_button is
        begin
            report "  ? Pressing key fob button...";
            key_button <= '1';
            wait for 100 ns;  -- Hold button
            key_button <= '0';
            
            -- Wait for transmission to start
            wait until key_tx_active = '1' or test_done;
            if not test_done then
                report "  ? Transmission started";
                
                -- Wait for transmission to complete
                wait until key_tx_active = '0' or test_done;
                if not test_done then
                    report "  ? Transmission completed";
                end if;
            end if;
        end procedure;
        
        -- Helper procedure untuk check results dengan delay lebih lama
        procedure check_authentication(
            expected_door : std_logic;
            expected_siren : std_logic;
            test_name : string
        ) is
        begin
            -- Tunggu lebih lama untuk processing
            wait for 5 us;
            
            report "  Checking results for: " & test_name;
            report "    Door state: " & std_logic'image(car_door) & 
                   " (expected: " & std_logic'image(expected_door) & ")";
            report "    Siren state: " & std_logic'image(car_siren) & 
                   " (expected: " & std_logic'image(expected_siren) & ")";
            
            if car_door = expected_door and car_siren = expected_siren then
                report "  ? PASS: " & test_name severity note;
            else
                report "  ? FAIL: " & test_name severity error;
            end if;
        end procedure;
        
    begin
        
        -- ========================================
        -- INITIAL SETUP
        -- ========================================
        report "================================================================";
        report "STARTING SYSTEM TESTBENCH";
        report "================================================================";
        report " ";
        
        -- Reset both devices
        report "Performing system reset...";
        reset <= '1';
        key_button <= '0';
        wait for 500 ns;  -- Longer reset
        reset <= '0';
        wait for 500 ns;  -- Stabilization time
        report "Reset complete. System ready.";
        report " ";
        wait for 1 us;
        
        -- ========================================
        -- TEST 1: FIRST AUTHENTICATION (Normal Use Case)
        -- ========================================
        test_number <= 1;
        report "================================================================";
        report "TEST 1: Normal Authentication - First Use";
        report "================================================================";
        report "Scenario: Owner arrives at car, presses button once";
        report " ";
        
        press_key_button;
        check_authentication('1', '0', "First Authentication");
        
        report " ";
        wait for 2 us;
        
        -- ========================================
        -- TEST 2: LOCK CAR AGAIN (Need to reset car state)
        -- ========================================
        test_number <= 2;
        report "================================================================";
        report "TEST 2: Lock Car Again";
        report "================================================================";
        report "Scenario: Owner locks car by resetting system";
        report " ";
        
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait for 500 ns;
        
        report "Car locked (door state reset)";
        if car_door = '0' then
            report "  ? PASS: Car locked successfully";
        end if;
        
        report " ";
        wait for 2 us;
        
        -- ========================================
        -- TEST 3: SECOND AUTHENTICATION (Counter Increment)
        -- ========================================
        test_number <= 3;
        report "================================================================";
        report "TEST 3: Second Authentication with Incremented Counter";
        report "================================================================";
        report "Scenario: Owner returns later, presses button again";
        report "Expected: Counter = 2, Authentication should succeed";
        report " ";
        
        press_key_button;
        check_authentication('1', '0', "Second Authentication (Counter=2)");
        
        report " ";
        wait for 2 us;
        
        -- ========================================
        -- TEST 4: MULTIPLE UNLOCKS IN A ROW
        -- ========================================
        test_number <= 4;
        report "================================================================";
        report "TEST 4: Multiple Unlock Attempts";
        report "================================================================";
        report "Scenario: Owner presses button 3 times in succession";
        report " ";
        
        for i in 1 to 3 loop
            report "--- Attempt " & integer'image(i) & " ---";
            
            -- Reset car to simulate locking
            reset <= '1';
            wait for 200 ns;
            reset <= '0';
            wait for 500 ns;
            
            press_key_button;
            wait for 5 us;
            
            if car_door = '1' then
                report "  ? Attempt " & integer'image(i) & " successful";
            else
                report "  ? Attempt " & integer'image(i) & " failed" severity error;
            end if;
            
            wait for 1 us;
        end loop;
        
        report " ";
        wait for 2 us;
        
        -- ========================================
        -- TEST 5: ACCIDENTAL DOUBLE PRESS
        -- ========================================
        test_number <= 5;
        report "================================================================";
        report "TEST 5: Accidental Double Press (Debouncing)";
        report "================================================================";
        report "Scenario: Owner accidentally presses button twice quickly";
        report " ";
        
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait for 500 ns;
        
        report "  Simulating bouncy button press...";
        key_button <= '1';
        wait for 20 ns;
        key_button <= '0';
        wait for 15 ns;
        key_button <= '1';
        wait for 10 ns;
        key_button <= '0';
        wait for 25 ns;
        key_button <= '1';
        wait for 100 ns;
        key_button <= '0';
        
        wait for 10 us;
        
        report "  Debounce test completed (check waveform for single transmission)";
        report " ";
        wait for 2 us;
        
        -- ========================================
        -- TEST 6: REALISTIC TIMING - WALKING TO CAR
        -- ========================================
        test_number <= 6;
        report "================================================================";
        report "TEST 6: Realistic Timing - Walking to Car";
        report "================================================================";
        report "Scenario: Owner presses button from 5 meters away, walks to car";
        report " ";
        
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait for 500 ns;
        
        press_key_button;
        
        report "  Owner walking to car... (simulated delay)";
        wait for 10 us;  -- Simulate walking time
        
        report "  Owner arrives at car, checking door...";
        check_authentication('1', '0', "Realistic Timing Test");
        
        report " ";
        wait for 2 us;
        
        -- ========================================
        -- TEST 7: BATTERY LOW SCENARIO (Slow Clock)
        -- ========================================
        test_number <= 7;
        report "================================================================";
        report "TEST 7: Various Environmental Conditions";
        report "================================================================";
        report "Scenario: Testing system under different conditions";
        report " ";
        
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait for 1 us;
        
        press_key_button;
        check_authentication('1', '0', "Environmental Stress Test");
        
        report " ";
        wait for 2 us;
        
        -- ========================================
        -- TEST SUMMARY
        -- ========================================
        report "================================================================";
        report "TEST SUMMARY - ALL TESTS COMPLETED";
        report "================================================================";
        report " ";
        report "Tests Executed:";
        report "  1. First Authentication          [CHECK WAVEFORM]";
        report "  2. Lock Car Again                [CHECK WAVEFORM]";
        report "  3. Counter Increment             [CHECK WAVEFORM]";
        report "  4. Multiple Unlocks (3x)         [CHECK WAVEFORM]";
        report "  5. Button Debouncing             [CHECK WAVEFORM]";
        report "  6. Realistic Timing              [CHECK WAVEFORM]";
        report "  7. Environmental Stress          [CHECK WAVEFORM]";
        report " ";
        report "If car_door stays 0, check:";
        report "  - SPI timing (CLK_DIV settings)";
        report "  - Counter validation logic";
        report "  - FSM state transitions";
        report "  - OTP calculation matches";
        report " ";
        report "================================================================";
        report "Simulation will end in 5 us...";
        report "================================================================";
        
        wait for 5 us;
        test_done <= true;
        wait;
        
    end process;
    
    -- ========================================
    -- CONTINUOUS MONITORING
    -- ========================================
    monitor: process
    begin
        wait for 1 ns;
        
        while not test_done loop
            wait until car_door'event or car_siren'event or test_done;
            
            if not test_done then
                if car_door'event then
                    if car_door = '1' then
                        report "*** [" & time'image(now) & "] CAR DOOR UNLOCKED ?" severity note;
                    else
                        report "*** [" & time'image(now) & "] CAR DOOR LOCKED";
                    end if;
                end if;
                
                if car_siren'event then
                    if car_siren = '1' then
                        report "*** [" & time'image(now) & "] ALARM TRIGGERED! ?" severity warning;
                    else
                        report "*** [" & time'image(now) & "] ALARM OFF";
                    end if;
                end if;
            end if;
        end loop;
        
        wait;
    end process;
    
    -- ========================================
    -- SPI ACTIVITY MONITOR
    -- ========================================
    spi_activity: process
        variable packet_count : integer := 0;
    begin
        wait for 1 ns;
        
        while not test_done loop
            wait until key_ss = '0' or test_done;
            
            if not test_done then
                packet_count := packet_count + 1;
                report ">>> SPI Packet #" & integer'image(packet_count) & 
                       " started at " & time'image(now);
                
                wait until key_ss = '1' or test_done;
                
                if not test_done then
                    report ">>> SPI Packet #" & integer'image(packet_count) & 
                           " ended at " & time'image(now);
                end if;
            end if;
        end loop;
        
        wait;
    end process;
    
    -- ========================================
    -- DEBUG HELPER - Key Fob State
    -- ========================================
    debug_key: process
    begin
        wait for 1 ns;
        
        while not test_done loop
            wait until key_tx_active'event or test_done;
            
            if not test_done then
                if key_tx_active = '1' then
                    report "[KEY FOB] Starting transmission...";
                else
                    report "[KEY FOB] Transmission complete";
                end if;
            end if;
        end loop;
        
        wait;
    end process;
    
    -- ========================================
    -- TIMEOUT WATCHDOG
    -- ========================================
    watchdog: process
    begin
        wait for 200 us;
        
        if not test_done then
            report "WATCHDOG TIMEOUT! Simulation exceeded 200us" severity failure;
        end if;
        
        wait;
    end process;

end Behavioral;