library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Key_Database is
    Port ( 
           clk        : in  STD_LOGIC;                     -- Clock sistem
           User_ID    : in  STD_LOGIC_VECTOR (1 downto 0); -- Input ID (00, 01, 10, 11)
           Secret_Key_Out : out STD_LOGIC_VECTOR (31 downto 0) -- Output: Kunci Rahasia (K)
           );
end Key_Database;

architecture Behavioral of Key_Database is

    -- Tipe array untuk menyimpan 4 data masing-masing 32-bit
    type key_rom_type is array (0 to 3) of std_logic_vector(31 downto 0);

    -- Isi Database Kunci Rahasia (Hardcoded)
    constant KEY_ROM : key_rom_type := (
        0 => x"11111111", -- Kunci rahasia untuk User/Remote 0
        1 => x"AABBCCDD", -- Kunci rahasia untuk User/Remote 1
        2 => x"12345678", -- Kunci rahasia untuk User/Remote 2
        3 => x"FEDCBA98"  -- Kunci rahasia untuk User/Remote 3
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Mengeluarkan kunci berdasarkan User_ID yang dipilih
            Secret_Key_Out <= KEY_ROM(to_integer(unsigned(User_ID)));
        end if;
    end process;

end Behavioral;