library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Master is
    Generic (
        CLK_DIV : integer := 4
    );
    Port (
        clk_sys : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        start   : in  STD_LOGIC;
        data_in : in  STD_LOGIC_VECTOR (31 downto 0);
        SCK     : out STD_LOGIC;
        SS      : out STD_LOGIC;
        MOSI    : out STD_LOGIC;
        busy    : out STD_LOGIC
    );
end SPI_Master;

architecture Behavioral of SPI_Master is
    type state_type is (IDLE, TRANSFER);
    signal state : state_type := IDLE;
    signal shift_reg : std_logic_vector(31 downto 0);
    signal bit_cnt   : integer range 0 to 32;
    signal clk_cnt   : integer range 0 to CLK_DIV;
    signal sck_int   : std_logic := '0';
    signal mosi_int  : std_logic := '0';
begin
    SCK  <= sck_int;
    MOSI <= mosi_int;
    
    process (clk_sys, rst)
    begin
        if rst = '1' then
            state     <= IDLE;
            SS        <= '1';
            sck_int   <= '0';
            mosi_int  <= '0';
            busy      <= '0';
            bit_cnt   <= 0;
            clk_cnt   <= 0;
            shift_reg <= (others => '0');
        elsif rising_edge(clk_sys) then
            case state is
                when IDLE =>
                    SS        <= '1';
                    sck_int   <= '0';
                    busy      <= '0';
                    mosi_int  <= '0';
                    bit_cnt   <= 0;
                    if start = '1' then
                        shift_reg <= data_in;
                        state     <= TRANSFER;
                        SS        <= '0';
                        busy      <= '1';
                        clk_cnt   <= 0;
                        mosi_int  <= data_in(31);
                    end if;
                when TRANSFER =>
                    if clk_cnt = CLK_DIV - 1 then
                        clk_cnt <= 0;
                        if sck_int = '0' then
                            sck_int <= '1';
                        else
                            sck_int <= '0';
                            if bit_cnt < 31 then
                                bit_cnt <= bit_cnt + 1;
                                mosi_int <= shift_reg(30 - bit_cnt);
                            else
                                state <= IDLE;
                                SS    <= '1';
                                busy  <= '0';
                            end if;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
