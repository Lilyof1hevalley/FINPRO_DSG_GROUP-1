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

    -- ==========================================
    -- DEKLARASI FUNGSI (FUNCTION)
    -- ==========================================
    -- Fungsi ini menerima input vector dan jumlah geseran (integer)
    -- lalu mengembalikan vector hasil geseran.
    function Func_ShiftLeft (
        val_in : std_logic_vector(31 downto 0); -- Input data
        n      : integer                        -- Mau geser berapa bit?
    ) return std_logic_vector is
        variable v_result : std_logic_vector(31 downto 0);
    begin
        -- Konversi ke unsigned -> lakukan shift -> kembalikan ke std_logic_vector
        v_result := std_logic_vector(shift_left(unsigned(val_in), n));
        return v_result;
    end function;

begin

    -- ==========================================
    -- LOGIKA UTAMA
    -- ==========================================

    -- 1. Langkah Pertama: XOR
    T1 <= Counter xor Secret_Key;
    
    -- 2. Langkah Kedua: Shift Left menggunakan FUNGSI
    -- Kita panggil fungsi yang sudah dibuat di atas
    OTP_Result <= Func_ShiftLeft(T1, 5);

end Behavioral;