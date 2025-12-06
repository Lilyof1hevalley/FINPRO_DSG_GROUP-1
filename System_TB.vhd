library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity System_TB is
-- Testbench tidak memiliki port input/output
end System_TB;

architecture Behavioral of System_TB is

    -- 1. KOMPONEN PENGIRIM: KEY (REMOTE)
    component Key
    Port ( 
           clk        : in  STD_LOGIC;
           reset      : in  STD_LOGIC;
           Button     : in  STD_LOGIC;
           SPI_SCK    : out STD_LOGIC;
           SPI_MOSI   : out STD_LOGIC;
           SPI_SS     : out STD_LOGIC;
           Tx_Active  : out STD_LOGIC
           );
    end component;

    -- 2. KOMPONEN PENERIMA: CAR (MOBIL)
    component Car
    Port ( 
           clk            : in  STD_LOGIC;
           reset          : in  STD_LOGIC;
           SPI_SCLK       : in  STD_LOGIC;
           SPI_MOSI       : in  STD_LOGIC;
           SPI_CS_N       : in  STD_LOGIC;
           SPI_MISO       : out STD_LOGIC;
           Door_Lock      : out STD_LOGIC;
           Siren          : out STD_LOGIC
           );
    end component;

    -- 3. SIGNAL PENGHUBUNG (KABEL VIRTUAL)
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    
    -- Kabel Komunikasi SPI (Udara/Wireless)
    signal wire_sck     : std_logic;
    signal wire_mosi    : std_logic;
    signal wire_ss      : std_logic;
    signal wire_miso    : std_logic; -- Feedback dari Mobil (Opsional)
    
    -- Input Remote
    signal key_button   : std_logic := '0';
    signal key_tx_active: std_logic;
    
    -- Output Mobil
    signal car_door     : std_logic;
    signal car_siren    : std_logic;

    -- Clock Config (100 MHz = 10 ns)
    constant clk_period : time := 10 ns;
 
begin
 
    -- 4. INSTANSIASI REMOTE (KEY)
    Remote_Unit: Key PORT MAP (
          clk       => clk,
          reset     => reset,
          Button    => key_button,
          SPI_SCK   => wire_sck,  -- Output Key masuk ke kabel SCK
          SPI_MOSI  => wire_mosi, -- Output Key masuk ke kabel MOSI
          SPI_SS    => wire_ss,   -- Output Key masuk ke kabel SS
          Tx_Active => key_tx_active
        );

    -- 5. INSTANSIASI MOBIL (CAR)
    Vehicle_Unit: Car PORT MAP (
          clk       => clk,
          reset     => reset,
          SPI_SCLK  => wire_sck,  -- Input Car ambil dari kabel SCK
          SPI_MOSI  => wire_mosi, -- Input Car ambil dari kabel MOSI
          SPI_CS_N  => wire_ss,   -- Input Car ambil dari kabel SS
          SPI_MISO  => wire_miso, -- Output Car ke kabel MISO
          Door_Lock => car_door,
          Siren     => car_siren
        );

    -- 6. PROSES PEMBUATAN CLOCK
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
 

    -- 7. PROSES STIMULUS (SKENARIO)
    stim_proc: process
    begin		
        -- A. RESET SYSTEM
        reset <= '1';
        wait for 100 ns;	
        reset <= '0';
        wait for 100 ns;

        -- Pastikan kondisi awal aman (Pintu Terkunci)
        -- car_door harus '0' di waveform saat ini

        ------------------------------------------------------------
        -- SKENARIO: PEMILIK MEMBUKA PINTU (Rolling Code #1)
        ------------------------------------------------------------
        -- 1. Tekan Tombol di Remote
        key_button <= '1';
        wait for 50 ns; -- Tahan tombol sebentar
        key_button <= '0'; -- Lepas tombol
        
        -- 2. Tunggu Proses Transmisi & Verifikasi
        -- Key akan mengirim 3 paket @ 32-bit via SPI yang lambat.
        -- Mobil butuh waktu menerima, merakit paket, dan menghitung.
        -- Kita beri waktu cukup lama (15 mikrodetik).
        wait for 15 us; 
        
        -- EKSPEKTASI:
        -- Lihat sinyal 'car_door' di waveform.
        -- Seharusnya naik menjadi '1' (High) di akhir periode ini.
        -- Sinyal 'car_siren' harus tetap '0'.
        
        
        -- (Opsional) Test Rolling Code berikutnya
        -- Tekan tombol lagi untuk melihat counter naik dan pintu tetap terbuka (refresh)
        -- key_button <= '1'; wait for 50 ns; key_button <= '0';
        -- wait for 15 us;
        
        -- Selesai
        wait;
    end process;

end Behavioral;