library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Key_FSM is
    Port ( 
           clk           : in  STD_LOGIC;
           reset         : in  STD_LOGIC;
           Button_Press  : in  STD_LOGIC;
           SPI_Busy      : in  STD_LOGIC;
           SPI_Start     : out STD_LOGIC;
           Packet_Select : out STD_LOGIC_VECTOR(1 downto 0);
           Inc_Counter   : out STD_LOGIC
           );
end Key_FSM;

architecture Behavioral of Key_FSM is
    type state_type is (
        ST_IDLE,
        ST_START_ID, ST_WAIT_BUSY_ID, ST_WAIT_DONE_ID, ST_GAP_1,
        ST_START_CNT, ST_WAIT_BUSY_CNT, ST_WAIT_DONE_CNT, ST_GAP_2,
        ST_START_OTP, ST_WAIT_BUSY_OTP, ST_WAIT_DONE_OTP,
        ST_UPDATE
    );
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
    
    process(current_state, Button_Press, SPI_Busy)
    begin
        next_state <= current_state;
        SPI_Start <= '0';
        Packet_Select <= "00";
        Inc_Counter <= '0';
        
        case current_state is
            when ST_IDLE =>
                if Button_Press = '1' then
                    next_state <= ST_START_ID;
                end if;
                
            -- Paket 1: User ID
            when ST_START_ID =>
                SPI_Start <= '1';
                Packet_Select <= "00";
                next_state <= ST_WAIT_BUSY_ID;
            when ST_WAIT_BUSY_ID =>
                Packet_Select <= "00";
                if SPI_Busy = '1' then
                    next_state <= ST_WAIT_DONE_ID;
                end if;
            when ST_WAIT_DONE_ID =>
                Packet_Select <= "00";
                if SPI_Busy = '0' then
                    next_state <= ST_GAP_1;
                end if;
            when ST_GAP_1 =>
                Packet_Select <= "01";
                next_state <= ST_START_CNT;
                
            -- Paket 2: Counter
            when ST_START_CNT =>
                SPI_Start <= '1';
                Packet_Select <= "01";
                next_state <= ST_WAIT_BUSY_CNT;
            when ST_WAIT_BUSY_CNT =>
                Packet_Select <= "01";
                if SPI_Busy = '1' then
                    next_state <= ST_WAIT_DONE_CNT;
                end if;
            when ST_WAIT_DONE_CNT =>
                Packet_Select <= "01";
                if SPI_Busy = '0' then
                    next_state <= ST_GAP_2;
                end if;
            when ST_GAP_2 =>
                Packet_Select <= "10";
                next_state <= ST_START_OTP;
                
            -- Paket 3: OTP
            when ST_START_OTP =>
                SPI_Start <= '1';
                Packet_Select <= "10";
                next_state <= ST_WAIT_BUSY_OTP;
            when ST_WAIT_BUSY_OTP =>
                Packet_Select <= "10";
                if SPI_Busy = '1' then
                    next_state <= ST_WAIT_DONE_OTP;
                end if;
            when ST_WAIT_DONE_OTP =>
                Packet_Select <= "10";
                if SPI_Busy = '0' then
                    next_state <= ST_UPDATE;
                end if;
                
            when ST_UPDATE =>
                Inc_Counter <= '1';
                next_state <= ST_IDLE;
        end case;
    end process;
end Behavioral;
