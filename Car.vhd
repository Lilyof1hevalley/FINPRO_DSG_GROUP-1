library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Car is
    Port ( 
           clk            : in  STD_LOGIC;
           reset          : in  STD_LOGIC;
           
           -- INPUT BARU: SPI INTERFACE (Bukan paralel lagi)
           SPI_SCLK       : in  STD_LOGIC;
           SPI_MOSI       : in  STD_LOGIC;
           SPI_CS_N       : in  STD_LOGIC;
           SPI_MISO       : out STD_LOGIC; -- Opsional, untuk feedback ke remote
           
           -- Output Fisik Mobil
           Door_Lock      : out STD_LOGIC;
           Siren          : out STD_LOGIC
           );
end Car;

architecture Behavioral of Car is

    -- 1. KOMPONEN SPI SLAVE
    component SPI_Slave
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
    end component;

    -- 2. KOMPONEN LAINNYA (Sama seperti sebelumnya)
    component Key_Database
    Port ( 
           clk            : in  STD_LOGIC;
           User_ID        : in  STD_LOGIC_VECTOR (1 downto 0);
           Secret_Key_Out : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;

    component OTP_Generator
    Port ( 
           Counter    : in  STD_LOGIC_VECTOR (31 downto 0);
           Secret_Key : in  STD_LOGIC_VECTOR (31 downto 0);
           OTP_Result : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;

    component Car_FSM
    Port ( 
           clk             : in  STD_LOGIC;
           reset           : in  STD_LOGIC;
           Remote_Trigger  : in  STD_LOGIC;
           Code_Is_Correct : in  STD_LOGIC;
           Door_Open       : out STD_LOGIC;
           Alarm_Siren     : out STD_LOGIC;
           Check_Enable    : out STD_LOGIC
    );
    end component;

    -- SIGNAL SPI & DATA ASSEMBLY
    signal reset_n        : std_logic;
    signal spi_data_out   : std_logic_vector(31 downto 0);
    signal spi_new_data   : std_logic;
    
    -- Register untuk menyimpan data yang diterima bertahap
    signal Reg_User_ID    : std_logic_vector(1 downto 0);
    signal Reg_Counter    : std_logic_vector(31 downto 0);
    signal Reg_OTP_Code   : std_logic_vector(31 downto 0);
    
    -- Counter paket (0: Tunggu ID, 1: Tunggu Counter, 2: Tunggu OTP)
    signal Packet_State   : integer range 0 to 3 := 0;
    signal Internal_Trigger : std_logic := '0'; -- Trigger FSM setelah semua paket lengkap

    -- SIGNAL LOGIKA
    signal Internal_Key   : std_logic_vector(31 downto 0);
    signal Expected_OTP   : std_logic_vector(31 downto 0);
    signal Match_Flag     : std_logic;
    signal FSM_Enable     : std_logic;

begin

    reset_n <= not reset; -- SPI Slave pakai Active Low reset

    -- A. INSTANSIASI SPI SLAVE
    SPI_Unit: SPI_Slave PORT MAP (
        CLK_IN       => clk,
        RESET_N      => reset_n,
        SPI_SCLK     => SPI_SCLK,
        SPI_MOSI     => SPI_MOSI,
        SPI_CS_N     => SPI_CS_N,
        DATA_IN      => x"00000000", -- Dummy response (misal status mobil)
        DATA_OUT     => spi_data_out,
        NEW_DATA     => spi_new_data,
        SPI_MISO_OUT => SPI_MISO
    );

    -- B. LOGIKA PENERIMAAN PAKET (DATA ASSEMBLY)
    -- Remote mengirim 3 paket berurutan: ID -> Counter -> OTP
    process(clk, reset)
    begin
        if reset = '1' then
            Packet_State <= 0;
            Internal_Trigger <= '0';
            Reg_User_ID <= (others => '0');
            Reg_Counter <= (others => '0');
            Reg_OTP_Code <= (others => '0');
        elsif rising_edge(clk) then
            Internal_Trigger <= '0'; -- Default low (pulse)
            
            if spi_new_data = '1' then
                case Packet_State is
                    when 0 => -- Terima Paket 1: USER ID
                        Reg_User_ID <= spi_data_out(1 downto 0); -- Ambil 2 bit terbawah
                        Packet_State <= 1;
                        
                    when 1 => -- Terima Paket 2: COUNTER
                        Reg_Counter <= spi_data_out;
                        Packet_State <= 2;
                        
                    when 2 => -- Terima Paket 3: OTP CODE
                        Reg_OTP_Code <= spi_data_out;
                        Packet_State <= 0; -- Reset untuk penerimaan berikutnya
                        Internal_Trigger <= '1'; -- Trigger FSM untuk mengecek!
                        
                    when others =>
                        Packet_State <= 0;
                end case;
            end if;
        end if;
    end process;

    -- C. KOMPONEN UTAMA (Sama seperti sebelumnya, tapi pakai Register Internal)
    
    DB_Unit: Key_Database PORT MAP (
        clk => clk,
        User_ID => Reg_User_ID, -- Dari hasil SPI
        Secret_Key_Out => Internal_Key
    );

    Calc_Unit: OTP_Generator PORT MAP (
        Counter => Reg_Counter, -- Dari hasil SPI
        Secret_Key => Internal_Key,
        OTP_Result => Expected_OTP
    );

    process(Reg_OTP_Code, Expected_OTP)
    begin
        if Reg_OTP_Code = Expected_OTP then
            Match_Flag <= '1';
        else
            Match_Flag <= '0';
        end if;
    end process;

    Control_Unit: Car_FSM PORT MAP (
        clk => clk,
        reset => reset,
        Remote_Trigger => Internal_Trigger, -- Trigger dari logika assembly SPI
        Code_Is_Correct => Match_Flag,
        Door_Open => Door_Lock,
        Alarm_Siren => Siren,
        Check_Enable => FSM_Enable
    );

end Behavioral;