ini Counter_Inc
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Counter_Inc is
    Port (
        clk      : in  STD_LOGIC;                      --system clock
        reset    : in  STD_LOGIC;                      --synchronus reset
        enable   : in  STD_LOGIC;                      --en counting
        inc      : in  STD_LOGIC;                      --increment pulse
        load     : in  STD_LOGIC;                      --load new value
        data_in  : in  STD_LOGIC_VECTOR(31 downto 0);  --data to load
        count    : out STD_LOGIC_VECTOR(31 downto 0);  --the current count value
        overflow : out STD_LOGIC                       --overflow indicator (1 cycle pulse)
    );
end Counter_Inc;

architecture Behavioral of Counter_Inc is
    signal internal_count : unsigned(31 downto 0) := (others => '0');  --the internal counter
    signal overflow_reg   : std_logic := '0';                          --this is overflow flag
begin
    process(clk)
    begin
        if rising_edge(clk) then
            overflow_reg <= '0';  --clear overflow flag (pulse only 1 cycle)
            
            if reset = '1' then
                --synchronous reset: clear counter to 0
                internal_count <= (others => '0');
                
            elsif load = '1' then
                --load to set counter to custom value
                internal_count <= unsigned(data_in);
                
            elsif enable = '1' and inc = '1' then
                --check for overflow
                if internal_count = x"FFFFFFFF" then
                    internal_count <= (others => '0');
                    overflow_reg <= '1';  --set overflow flag if yes
                else
                    internal_count <= internal_count + 1;
                end if;
            end if;
            
        end if;
    end process;
    
    --output assignments
    count    <= std_logic_vector(internal_count);
    overflow <= overflow_reg;
end Behavioral;