library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Car_FSM is
    Port ( 
           clk             : in  STD_LOGIC;-- ini buat sistem clocknya
           reset           : in  STD_LOGIC; -- ini reset buat balik ke state idle
           Remote_Trigger  : in  STD_LOGIC;-- ini signal kalo ada data dari remote
           Code_Is_Correct : in  STD_LOGIC;-- ini signal kalo otp dan counternya valid
           Door_Open       : out STD_LOGIC;-- ini status mobilnya (kalo 1 berarti unlocked)
           Alarm_Siren     : out STD_LOGIC;-- ini status alarmnya kalo 1 berarti bunyi alarmnya
           Check_Enable    : out STD_LOGIC;-- ini status buat tau kalo lagi ngecek otp
           Update_DB       : out STD_LOGIC-- ini signal buat update database
           );
end Car_FSM;

architecture Behavioral of Car_FSM is
    type state_type is (ST_IDLE, ST_CHECK, ST_OPEN, ST_ALARM, ST_UPDATE);-- statenya itu mulai dari nunggu (idle) itu mobil masi kekunci, trus ngecek otp dan counter, trus mobil unlocked, trus itu ada kalo gagal, alarm bunyi
    signal current_state, next_state : state_type;
begin
    process(clk, reset)
    begin
        if reset = '1' then -- ini kalo ke reset
            current_state <= ST_IDLE;-- statenya balik ke nunggu (idle)
        elsif rising_edge(clk) then-- tapi kalo clocknya naik
            current_state <= next_state;-- ke state selanjutnya
        end if;
    end process;
    
    process(current_state, Remote_Trigger, Code_Is_Correct)
    begin
        next_state <= current_state;-- ini di set ke state yang sekarang dulu
        Door_Open <= '0'; -- ini ngeset ke lock dulu mobilnya
        Alarm_Siren <= '0'; -- ini alarm mati
        Check_Enable <= '0'; -- ini status ngecek otp dan counter belom (0 dulu)
        Update_DB <= '0';  -- lagi ga ada yang perlu di update ke database
        
        case current_state is
            when ST_IDLE =>
                if Remote_Trigger = '1' then-- ini kalo ada data masuk atau remote
                    next_state <= ST_CHECK; -- pindah state ke check
                end if;
                
            when ST_CHECK =>
                Check_Enable <= '1'; -- nah nyala status check otp dan counternya
                if Code_Is_Correct = '1' then -- kalo valid otp dan counternya
                    next_state <= ST_UPDATE; -- status mobilnya unlocked (status)
                else
                    next_state <= ST_ALARM;-- kalo ga valid ya alarm nyala
                end if;
            
            when ST_UPDATE =>
                Update_DB <= '1';-- nah baru deh update ke database, counter terbarunya
                next_state <= ST_OPEN; -- mobil bakal unlocked terus
                
            when ST_OPEN =>
                Door_Open <= '1';-- nah mobilnya kan unlocked (pintu)
                next_state <= ST_OPEN; -- mobil bakal unlocked terus
                
            when ST_ALARM =>
                Alarm_Siren <= '1'; -- nah ini alarm nya nyala
                next_state <= ST_ALARM; -- bakal nyala terus alarmnya
        end case;
    end process;
end Behavioral;
