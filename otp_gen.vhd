library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OTP_Generator is
    Port ( 
           Counter    : in  STD_LOGIC_VECTOR (31 downto 0);
           Secret_Key : in  STD_LOGIC_VECTOR (31 downto 0);
           OTP_Result : out STD_LOGIC_VECTOR (31 downto 0)
           );
end OTP_Generator;

architecture Behavioral of OTP_Generator is
    --im changing it into more secure
begin
    process(Counter, Secret_Key)
    variable temp : unsigned(31 downto 0);
    begin
        temp<=unsigned(Counter) xor unsigned(Secret_Key);
        temp<= temp + (temp rol 3); --rotate left
        temp<= temp + x"9E37"; -- golden ratio const (2^32/1.618) bcs its irrationally good
        temp<= temp rol 7;

    OTP_Result <= std_logic_vector(temp);

    end process;
end Behavioral;