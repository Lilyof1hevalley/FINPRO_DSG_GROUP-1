library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Counter_Inc is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;      
        enable   : in  STD_LOGIC;      
        inc      : in  STD_LOGIC;      --this is increment pulse
        load     : in  STD_LOGIC;      --load new value
        data_in  : in  STD_LOGIC_VECTOR(31 downto 0);
        count    : out STD_LOGIC_VECTOR(31 downto 0);
        overflow : out STD_LOGIC       --overflow indicator
    );
end Counter_Inc;

architecture Behavioral of Counter_Inc is
    signal internal_count : unsigned(31 downto 0) := (others => '0');
    signal overflow_reg   : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            overflow_reg <= '0';
            
            if reset = '1' then
                --synchronous reset to 0
                internal_count <= (others => '0');
                
            elsif load = '1' then
                --load custom value
                internal_count <= unsigned(data_in);
                
            elsif enable = '1' and inc = '1' then
                --increment with overflow handling
                if internal_count = x"FFFFFFFF" then
                    internal_count <= (others => '0');
                    overflow_reg <= '1';  --overflow flag
                else
                    internal_count <= internal_count + 1;
                end if;
            end if;
        end if;
    end process;
    
    count    <= std_logic_vector(internal_count);
    overflow <= overflow_reg;
end Behavioral;