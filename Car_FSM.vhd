library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Car_FSM is
    Port ( 
           clk             : in  STD_LOGIC;
           reset           : in  STD_LOGIC;
           
           -- Inputs
           Remote_Trigger  : in  STD_LOGIC; -- Sinyal "Ada data masuk dari remote"
           Code_Is_Correct : in  STD_LOGIC; -- Sinyal dari Komparator (1=Cocok, 0=Salah)
           
           -- Outputs
           Door_Open       : out STD_LOGIC; -- 1: Buka Pintu
           Alarm_Siren     : out STD_LOGIC; -- 1: Bunyikan Alarm
           Check_Enable    : out STD_LOGIC  -- 1: Perintahkan sistem untuk menghitung
           );
end Car_FSM;

architecture Behavioral of Car_FSM is

    -- Definisi State
    type state_type is (ST_IDLE, ST_CHECK, ST_OPEN, ST_ALARM);
    signal current_state, next_state : state_type;

begin

    -- 1. State Register (Pindah state saat rising edge clock)
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= ST_IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- 2. Next State Logic (Logika perpindahan state)
    process(current_state, Remote_Trigger, Code_Is_Correct)
    begin
        -- Default assignments agar tidak terjadi latch
        next_state <= current_state;
        Door_Open <= '0';
        Alarm_Siren <= '0';
        Check_Enable <= '0';

        case current_state is
            
            -- KONDISI AWAL: MOBIL TERKUNCI
            when ST_IDLE =>
                if Remote_Trigger = '1' then
                    next_state <= ST_CHECK; -- Jika ada sinyal remote, mulai pengecekan
                else
                    next_state <= ST_IDLE;
                end if;

            -- KONDISI PENGECEKAN
            when ST_CHECK =>
                Check_Enable <= '1'; -- Aktifkan komponen perhitungan
                
                -- Kita asumsikan hasil komparasi langsung tersedia (combinational)
                if Code_Is_Correct = '1' then
                    next_state <= ST_OPEN;  -- Sukses
                else
                    next_state <= ST_ALARM; -- Gagal/Maling
                end if;

            -- KONDISI PINTU TERBUKA
            when ST_OPEN =>
                Door_Open <= '1'; -- Buka Pintu
                -- Tetap di sini sampai di-reset (atau bisa tambah timer auto-lock)
                next_state <= ST_OPEN; 

            -- KONDISI ALARM MENYALA
            when ST_ALARM =>
                Alarm_Siren <= '1'; -- Bunyikan Sirine
                next_state <= ST_ALARM; -- Tetap bunyi sampai di-reset

        end case;
    end process;

end Behavioral;