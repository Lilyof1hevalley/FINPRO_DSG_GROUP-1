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
    signal T1 : std_logic_vector(31 downto 0);
    
    function Func_ShiftLeft (
        val_in : std_logic_vector(31 downto 0);
        n      : integer
    ) return std_logic_vector is
        variable v_result : std_logic_vector(31 downto 0);
    begin
        v_result := std_logic_vector(shift_left(unsigned(val_in), n));
        return v_result;
    end function;
begin
    T1 <= Counter xor Secret_Key;
    OTP_Result <= Func_ShiftLeft(T1, 5);
end Behavioral;