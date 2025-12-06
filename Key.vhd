library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Key is
    Port ( 
           clk        : in  STD_LOGIC;
           reset      : in  STD_LOGIC;
           Button     : in  STD_LOGIC; -- Tombol Remote
           
           -- Output SPI (Ke Udara/Mobil)
           SPI_SCK    : out STD_LOGIC;
           SPI_MOSI   : out STD_LOGIC;
           SPI_SS     : out STD_LOGIC;
           
           -- Debug LED (Opsional, nyala saat mengirim)
           Tx_Active  : out STD_LOGIC
           );
end Key;

architecture Behavioral of Key is

    -- 1. KOMPONEN OTP GENERATOR (Reuse)
    component OTP_Generator
    Port ( 
           Counter    : in  STD_LOGIC_VECTOR (31 downto 0);
           Secret_Key : in  STD_LOGIC_VECTOR (31 downto 0);
           OTP_Result : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;

    -- 2. KOMPONEN SPI MASTER (Reuse)
    component SPI_Master
    Generic ( CLK_DIV : integer := 4 );
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
    end component;

    -- 3. KOMPONEN KEY FSM
    component Key_FSM
    Port ( 
           clk           : in  STD_LOGIC;
           reset         : in  STD_LOGIC;
           Button_Press  : in  STD_LOGIC;
           SPI_Busy      : in  STD_LOGIC;
           SPI_Start     : out STD_LOGIC;
           Packet_Select : out STD_LOGIC_VECTOR(1 downto 0);
           Inc_Counter   : out STD_LOGIC
    );
    end component;

    -- KONFIGURASI REMOTE (HARDCODED)
    -- Ini mensimulasikan Chip Remote yang sudah diprogram pabrik
    constant MY_USER_ID    : std_logic_vector(1 downto 0)  := "00";        -- Remote milik User 0
    constant MY_SECRET_KEY : std_logic_vector(31 downto 0) := x"11111111"; -- Key User 0 (Sesuai DB Mobil)

    -- INTERNAL SIGNALS
    signal r_counter      : std_logic_vector(31 downto 0); -- Register Counter Internal
    signal w_otp_result   : std_logic_vector(31 downto 0); -- Kabel hasil hitungan OTP
    
    -- Kabel Kontrol FSM
    signal fsm_start_spi  : std_logic;
    signal fsm_pkt_sel    : std_logic_vector(1 downto 0);
    signal fsm_inc_cnt    : std_logic;
    signal spi_is_busy    : std_logic;
    
    -- Kabel Data SPI
    signal spi_data_mux   : std_logic_vector(31 downto 0); -- Data yang dipilih untuk dikirim

begin

    Tx_Active <= spi_is_busy; -- LED nyala kalau SPI sibuk

    -- A. PROSES COUNTER (Memori Internal Remote)
    -- Counter bertambah setiap kali FSM selesai mengirim satu siklus penuh
    process(clk, reset)
    begin
        if reset = '1' then
            -- Mulai dari 2 (Genap) sesuai workaround simulasi kita sebelumnya
            -- Atau bisa mulai dari 1, tergantung kebutuhan
            r_counter <= x"00000002"; 
        elsif rising_edge(clk) then
            if fsm_inc_cnt = '1' then
                r_counter <= std_logic_vector(unsigned(r_counter) + 1);
            end if;
        end if;
    end process;

    -- B. INSTANSIASI OTP GENERATOR
    -- Menghitung OTP berdasarkan Counter saat ini & Kunci Saya
    Gen_Unit: OTP_Generator PORT MAP (
        Counter    => r_counter,
        Secret_Key => MY_SECRET_KEY,
        OTP_Result => w_otp_result
    );

    -- C. MULTIPLEXER DATA (Memilih apa yang mau dikirim via SPI)
    -- Dikontrol oleh FSM (Packet_Select)
    process(fsm_pkt_sel, r_counter, w_otp_result)
    begin
        case fsm_pkt_sel is
            when "00" => -- Kirim User ID (Padding 0 di depan)
                spi_data_mux <= x"0000000" & "00" & MY_USER_ID;
            when "01" => -- Kirim Counter
                spi_data_mux <= r_counter;
            when "10" => -- Kirim OTP
                spi_data_mux <= w_otp_result;
            when others =>
                spi_data_mux <= (others => '0');
        end case;
    end process;

    -- D. INSTANSIASI KEY FSM
    -- Mengatur urutan pengiriman
    Control_Unit: Key_FSM PORT MAP (
        clk           => clk,
        reset         => reset,
        Button_Press  => Button,
        SPI_Busy      => spi_is_busy,
        SPI_Start     => fsm_start_spi,
        Packet_Select => fsm_pkt_sel,
        Inc_Counter   => fsm_inc_cnt
    );

    -- E. INSTANSIASI SPI MASTER
    -- Pengirim sinyal fisik
    SPI_Tx: SPI_Master 
    GENERIC MAP ( CLK_DIV => 4 ) -- Sesuaikan clock speed
    PORT MAP (
        clk_sys => clk,
        rst     => reset,
        start   => fsm_start_spi,
        data_in => spi_data_mux, -- Data masuk dari Mux
        SCK     => SPI_SCK,
        SS      => SPI_SS,
        MOSI    => SPI_MOSI,
        busy    => spi_is_busy
    );

end Behavioral;