-- Stores this key's credentials (single key only)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Key_Database is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        -- read interface
        read_en : in std_logic;
        my_id : out std_logic_vector(7 downto 0);
        my_key : out std_logic_vector(31 downto 0);
        my_counter : out std_logic_vector(7 downto 0);
        
        -- counter increment
        inc_counter : in std_logic
    );
end Key_Database;

architecture Behavioral of Key_Database is
    
    -- this key's stored credentials
    constant ID_VALUE : std_logic_vector(7 downto 0) := x"02";
    constant KEY_VALUE : std_logic_vector(31 downto 0) := x"0000000B";
    
    signal counter_value : std_logic_vector(7 downto 0) := x"05";
    
begin

    process(clk, rst)
    begin
        if rst = '1' then
            counter_value <= x"05";  -- reset to initial value
            my_id <= (others => '0');
            my_key <= (others => '0');
            my_counter <= (others => '0');
            
        elsif rising_edge(clk) then
            
            -- return stored credentials when requested
            if read_en = '1' then
                my_id <= ID_VALUE;
                my_key <= KEY_VALUE;
                my_counter <= counter_value;
            end if;
            
            -- increment counter after successful transaction
            if inc_counter = '1' then
                counter_value <= std_logic_vector(unsigned(counter_value) + 1);
            end if;
            
        end if;
    end process;

end Behavioral;