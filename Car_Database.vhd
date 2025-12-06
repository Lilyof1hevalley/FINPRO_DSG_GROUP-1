library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Car_Database is
    Port ( 
           clk        : in  STD_LOGIC;                     -- Clock sistem
           User_ID    : in  STD_LOGIC_VECTOR (1 downto 0); -- Input ID
           Car_ID_Out : out STD_LOGIC_VECTOR (31 downto 0) -- Output: ID Mobil
           );
end Car_Database;

architecture Behavioral of Car_Database is

    type car_rom_type is array (0 to 3) of std_logic_vector(31 downto 0);

    -- PERBAIKAN:
    -- Nilai Hex hanya boleh 0-9 dan A-F.
    -- Huruf M, W, H, N, dsb tidak bisa digunakan langsung dalam std_logic_vector hex.
    constant CAR_ROM : car_rom_type := (
        0 => x"CA500001", -- Valid
        1 => x"CA500002", -- Valid
        2 => x"BB000001", -- Sebelumnya "BBMW..." -> Diganti "BB00..." agar valid Hex
        3 => x"000DA999"  -- Sebelumnya "H0NDA..." -> Diganti "000DA..." agar valid Hex
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            Car_ID_Out <= CAR_ROM(to_integer(unsigned(User_ID)));
        end if;
    end process;

end Behavioral;