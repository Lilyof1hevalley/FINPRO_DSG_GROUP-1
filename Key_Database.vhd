library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Key_Database is
    Port ( 
           clk        : in  STD_LOGIC;
           User_ID    : in  STD_LOGIC_VECTOR (1 downto 0);
           Secret_Key_Out : out STD_LOGIC_VECTOR (31 downto 0)
           );
end Key_Database;

architecture Behavioral of Key_Database is
    type key_rom_type is array (0 to 3) of std_logic_vector(31 downto 0);
    
    constant KEY_ROM : key_rom_type := (
        0 => x"11111111",
        1 => x"AABBCCDD",
        2 => x"12345678",
        3 => x"FEDCBA98"
    );
begin
    process(clk)
    begin
        if rising_edge(clk) then
            Secret_Key_Out <= KEY_ROM(to_integer(unsigned(User_ID)));
        end if;
    end process;
end Behavioral;