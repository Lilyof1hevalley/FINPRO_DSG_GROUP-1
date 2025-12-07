library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPI_Slave is
    port (
        CLK_IN      : in  std_logic;
        RESET_N     : in  std_logic;
        SPI_SCLK    : in  std_logic;
        SPI_MOSI    : in  std_logic;
        SPI_CS_N    : in  std_logic;
        DATA_IN     : in  std_logic_vector(31 downto 0);
        DATA_OUT    : out std_logic_vector(31 downto 0);
        NEW_DATA    : out std_logic;
        SPI_MISO_OUT: out std_logic
    );
end entity SPI_Slave;

architecture rtl of SPI_Slave is
    signal tx_register_8   : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_data_32      : std_logic_vector(31 downto 0) := (others => '0');
    signal rx_register_32  : std_logic_vector(31 downto 0) := (others => '0');
    signal bit_counter     : integer range 0 to 7 := 0;
    signal byte_counter    : integer range 0 to 3 := 0;
    signal sclk_prev       : std_logic := '0';
    signal sclk_rising     : std_logic;
    signal cs_prev         : std_logic := '1';
    signal cs_falling      : std_logic;
    
    type t_slave_state is (STATE_IDLE, STATE_ACTIVE_TRANSFER);
    signal current_state : t_slave_state := STATE_IDLE;
begin
    process (CLK_IN)
    begin
        if rising_edge(CLK_IN) then
            sclk_prev <= SPI_SCLK;
            cs_prev   <= SPI_CS_N;
        end if;
    end process;
    
    sclk_rising <= (SPI_SCLK and not sclk_prev);
    cs_falling  <= (not SPI_CS_N and cs_prev);
    
    process (CLK_IN, RESET_N)
        variable v_rx_reg : std_logic_vector(31 downto 0);
    begin
        if RESET_N = '0' then
            rx_register_32 <= (others => '0');
            v_rx_reg       := (others => '0');
            tx_data_32     <= (others => '0');
            tx_register_8  <= (others => '0');
            bit_counter    <= 0;
            byte_counter   <= 0;
            NEW_DATA       <= '0';
            current_state  <= STATE_IDLE;
            
        elsif rising_edge(CLK_IN) then
            v_rx_reg := rx_register_32;
            NEW_DATA <= '0';
            
            case current_state is
                when STATE_IDLE =>
                    if cs_falling = '1' then
                        tx_data_32     <= DATA_IN;
                        byte_counter   <= 3;
                        tx_register_8  <= DATA_IN(31 downto 24);
                        bit_counter    <= 0;
                        v_rx_reg       := (others => '0');
                        rx_register_32 <= (others => '0');
                        current_state  <= STATE_ACTIVE_TRANSFER;
                    end if;
                    
                when STATE_ACTIVE_TRANSFER =>
                    if SPI_CS_N = '1' then
                        current_state <= STATE_IDLE;
                        bit_counter <= 0;
                        byte_counter <= 0;
                        
                    elsif sclk_rising = '1' then
                        v_rx_reg(byte_counter*8 + (7 - bit_counter)) := SPI_MOSI;
                        rx_register_32 <= v_rx_reg;
                        
                        tx_register_8 <= tx_register_8(6 downto 0) & '0';
                        
                        if bit_counter = 7 then
                            if byte_counter = 0 then
                                DATA_OUT <= v_rx_reg;
                                NEW_DATA <= '1';
                            else
                                byte_counter <= byte_counter - 1;
                                
                                case byte_counter is
                                    when 3 => tx_register_8 <= tx_data_32(23 downto 16);
                                    when 2 => tx_register_8 <= tx_data_32(15 downto 8);
                                    when 1 => tx_register_8 <= tx_data_32(7 downto 0);
                                    when others => tx_register_8 <= (others => '0');
                                end case;
                            end if;
                            bit_counter <= 0;
                        else
                            bit_counter <= bit_counter + 1;
                        end if;
                    end if;
            end case;
        end if;
    end process;
    
    SPI_MISO_OUT <= tx_register_8(7);
    
end architecture rtl;
