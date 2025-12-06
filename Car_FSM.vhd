library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Car_FSM is
    Port ( 
           clk             : in  STD_LOGIC;
           reset           : in  STD_LOGIC;
           Remote_Trigger  : in  STD_LOGIC;
           Code_Is_Correct : in  STD_LOGIC;
           Door_Open       : out STD_LOGIC;
           Alarm_Siren     : out STD_LOGIC;
           Check_Enable    : out STD_LOGIC;
           Update_DB       : out STD_LOGIC  -- NEW: Signal untuk update database
           );
end Car_FSM;

architecture Behavioral of Car_FSM is
    type state_type is (ST_IDLE, ST_CHECK, ST_OPEN, ST_ALARM);
    signal current_state, next_state : state_type;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= ST_IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    process(current_state, Remote_Trigger, Code_Is_Correct)
    begin
        next_state <= current_state;
        Door_Open <= '0';
        Alarm_Siren <= '0';
        Check_Enable <= '0';
        Update_DB <= '0';  -- NEW
        
        case current_state is
            when ST_IDLE =>
                if Remote_Trigger = '1' then
                    next_state <= ST_CHECK;
                else
                    next_state <= ST_IDLE;
                end if;
                
            when ST_CHECK =>
                Check_Enable <= '1';
                if Code_Is_Correct = '1' then
                    next_state <= ST_OPEN;
                else
                    next_state <= ST_ALARM;
                end if;
                
            when ST_OPEN =>
                Door_Open <= '1';
                Update_DB <= '1';  -- NEW: Update counter database saat sukses
                next_state <= ST_OPEN;
                
            when ST_ALARM =>
                Alarm_Siren <= '1';
                next_state <= ST_ALARM;
        end case;
    end process;
end Behavioral;
