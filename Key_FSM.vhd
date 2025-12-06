library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Key_FSM is
    Port ( 
           clk           : in  STD_LOGIC;
           reset         : in  STD_LOGIC;
           
           -- Inputs
           Button_Press  : in  STD_LOGIC;
           SPI_Busy      : in  STD_LOGIC;
           
           -- Outputs
           SPI_Start     : out STD_LOGIC;
           Packet_Select : out STD_LOGIC_VECTOR(1 downto 0);
           Inc_Counter   : out STD_LOGIC
           );
end Key_FSM;

architecture Behavioral of Key_FSM is

    type state_type is (
        ST_IDLE,
        
        -- Paket 1: ID
        ST_START_ID, 
        ST_WAIT_BUSY_ID,
        ST_WAIT_DONE_ID,
        ST_GAP_1,        -- [BARU] Jeda antar paket 1 & 2
        
        -- Paket 2: Counter
        ST_START_CNT,
        ST_WAIT_BUSY_CNT,
        ST_WAIT_DONE_CNT,
        ST_GAP_2,        -- [BARU] Jeda antar paket 2 & 3
        
        -- Paket 3: OTP
        ST_START_OTP,
        ST_WAIT_BUSY_OTP,
        ST_WAIT_DONE_OTP,
        
        ST_UPDATE
    );
    
    signal current_state, next_state : state_type;

begin

    -- 1. State Register
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= ST_IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- 2. Next State & Output Logic
    process(current_state, Button_Press, SPI_Busy)
    begin
        -- Default Outputs
        next_state <= current_state;
        SPI_Start <= '0';
        Packet_Select <= "00";
        Inc_Counter <= '0';

        case current_state is
            
            when ST_IDLE =>
                if Button_Press = '1' then
                    next_state <= ST_START_ID;
                else
                    next_state <= ST_IDLE;
                end if;

            -- ==========================================
            -- PAKET 1: USER ID
            -- ==========================================
            when ST_START_ID =>
                SPI_Start <= '1';      
                Packet_Select <= "00"; 
                next_state <= ST_WAIT_BUSY_ID;

            when ST_WAIT_BUSY_ID =>
                Packet_Select <= "00";
                if SPI_Busy = '1' then
                    next_state <= ST_WAIT_DONE_ID;
                else
                    next_state <= ST_WAIT_BUSY_ID;
                end if;

            when ST_WAIT_DONE_ID =>
                Packet_Select <= "00";
                if SPI_Busy = '0' then 
                     next_state <= ST_GAP_1; -- Selesai -> Masuk GAP dulu
                else
                     next_state <= ST_WAIT_DONE_ID;
                end if;
            
            -- JEDA & PREPARE DATA 2
            when ST_GAP_1 =>
                Packet_Select <= "01"; -- Siapkan data Counter SEBELUM start
                next_state <= ST_START_CNT;

            -- ==========================================
            -- PAKET 2: COUNTER
            -- ==========================================
            when ST_START_CNT =>
                SPI_Start <= '1';
                Packet_Select <= "01";
                next_state <= ST_WAIT_BUSY_CNT;

            when ST_WAIT_BUSY_CNT =>
                Packet_Select <= "01";
                if SPI_Busy = '1' then
                    next_state <= ST_WAIT_DONE_CNT;
                else
                    next_state <= ST_WAIT_BUSY_CNT;
                end if;

            when ST_WAIT_DONE_CNT =>
                Packet_Select <= "01";
                if SPI_Busy = '0' then 
                     next_state <= ST_GAP_2; -- Selesai -> Masuk GAP dulu
                else
                     next_state <= ST_WAIT_DONE_CNT;
                end if;

            -- JEDA & PREPARE DATA 3
            when ST_GAP_2 =>
                Packet_Select <= "10"; -- Siapkan data OTP SEBELUM start
                next_state <= ST_START_OTP;

            -- ==========================================
            -- PAKET 3: OTP CODE
            -- ==========================================
            when ST_START_OTP =>
                SPI_Start <= '1';
                Packet_Select <= "10";
                next_state <= ST_WAIT_BUSY_OTP;

            when ST_WAIT_BUSY_OTP =>
                Packet_Select <= "10";
                if SPI_Busy = '1' then
                    next_state <= ST_WAIT_DONE_OTP;
                else
                    next_state <= ST_WAIT_BUSY_OTP;
                end if;

            when ST_WAIT_DONE_OTP =>
                Packet_Select <= "10";
                if SPI_Busy = '0' then 
                     next_state <= ST_UPDATE;
                else
                     next_state <= ST_WAIT_DONE_OTP;
                end if;

            -- ==========================================
            -- UPDATE & FINISH
            -- ==========================================
            when ST_UPDATE =>
                Inc_Counter <= '1';
                next_state <= ST_IDLE; 

        end case;
    end process;

end Behavioral;