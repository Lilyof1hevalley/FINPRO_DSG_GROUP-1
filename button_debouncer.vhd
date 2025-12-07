ini Button Debouncer
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Button_Debouncer is
    Port(
        clk     : in  std_logic;  --system clock
        btn_in  : in  std_logic;  --button before bounced
        btn_out : out std_logic   --debounced button output
    );
end Button_Debouncer;

architecture Behavioral of Button_Debouncer is
    signal synchro_register : std_logic_vector(2 downto 0) := "000";
begin
    process(clk)
    begin
        if rising_edge(clk) then
            --this shifts register: shirt left kiri, input btn_in to LSB
            synchro_register <= synchro_register(1 downto 0) & btn_in;
            
            if synchro_register = "111" then
                btn_out <= '1'; 
                
            elsif synchro_register = "000" then
                btn_out <= '0'; 
            end if;

        end if;
    end process;
end Behavioral;

--examle case for this part is if a button was pressed so the logic was 1, and if not pressed logic 
--was 0, so if it was pressed example 0-1-0-1-1 => fsm will be trigger like times to times
--however with debouncing, the same input that was example like 1-1 it will be count as one time trigger for the fsm
