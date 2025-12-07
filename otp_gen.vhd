ini OTP gen
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OTP_Generator is
    Port ( 
           Counter    : in  STD_LOGIC_VECTOR (31 downto 0);  --counter value
           Secret_Key : in  STD_LOGIC_VECTOR (31 downto 0);  --secret key
           OTP_Result : out STD_LOGIC_VECTOR (31 downto 0)   --generated otp
           );
end OTP_Generator;

architecture Behavioral of OTP_Generator is
begin
    process(Counter, Secret_Key)
        variable temp : unsigned(31 downto 0);
    begin
        --xor counter with secret_Key (first mixing)
        temp := unsigned(Counter) xor unsigned(Secret_Key);
        
        --non-linear diffusion (add rotated version of itself)
        --rotate left 3 bits
        temp := temp + (temp rol 3);
        
        --golden ratio constant (to break patterns)
        temp := temp + x"9E37";
        
        --rotate left 7 bits
        temp := temp rol 7;
        
        --result
        OTP_Result <= std_logic_vector(temp);
    end process;
    
end Behavioral;