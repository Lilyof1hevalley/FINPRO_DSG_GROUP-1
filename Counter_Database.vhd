library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Counter_Database is
    Port ( 
           clk          : in  STD_LOGIC;
           reset        : in  STD_LOGIC;
           User_ID      : in  STD_LOGIC_VECTOR (1 downto 0);
           Last_Cnt_Out : out STD_LOGIC_VECTOR (31 downto 0);
           Write_En     : in  STD_LOGIC;
           New_Cnt_In   : in  STD_LOGIC_VECTOR (31 downto 0)
           );
end Counter_Database;

architecture Behavioral of Counter_Database is
    type ram_type is array (0 to 3) of std_logic_vector(31 downto 0);
    signal RAM : ram_type := (others => x"00000000");
begin
    process(clk, reset)
    begin
        if reset = '1' then
            RAM <= (others => x"00000000"); 
        elsif rising_edge(clk) then
            if Write_En = '1' then
                RAM(to_integer(unsigned(User_ID))) <= New_Cnt_In;
            end if;
        end if;
    end process;
    
    Last_Cnt_Out <= RAM(to_integer(unsigned(User_ID)));
end Behavioral;