library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Button_Debouncer is
    Port(
        clk     : in std_logic;
        btn_in  : in std_logic;
        btn_out : out std_logic;

    );

end Button_Debouncer;

architecture comp of Button_Debouncer is
    signal synchro_register : std_logic_vector(2 downto 0) := "000";
begin
    process(clk)
    begin
        if rising_edge(clk) then
            synchro_register <= synchro_register(1 downto 0) & btn_in;
            
            if synchro_register = "111" then
                btn_out <= "1";
            elsif synchro_register = "000" then
                btn_out <= "0";

            end if;
            end if;
        end process;
end comp;