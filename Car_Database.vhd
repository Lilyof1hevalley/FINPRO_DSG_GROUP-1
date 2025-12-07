Car Database
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Car_Database is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        -- Lookup interface to read credentials
        lookup_id : in std_logic_vector(7 downto 0);
        lookup_en : in std_logic;
        
        -- Lookup results
        key_found : out std_logic;
        stored_key : out std_logic_vector(31 downto 0);
        stored_counter : out std_logic_vector(7 downto 0);
        
        -- Counter update interface that used when authentication success
        update_en : in std_logic;
        update_id : in std_logic_vector(7 downto 0);
        update_counter : in std_logic_vector(7 downto 0)
    );
end Car_Database;

architecture Behavioral of Car_Database is
   -- Database Structure
    type key_record is record
        id      : std_logic_vector(7 downto 0);
        key     : std_logic_vector(31 downto 0);
        counter : std_logic_vector(7 downto 0);
        valid   : std_logic;
    end record;
    
    type db_array is array(0 to 3) of key_record;
    signal database : db_array := (
        0 => (id => x"02", key => x"0000000B", counter => x"00", valid => '1'), -- ✅ Key #2
        1 => (id => x"03", key => x"0000000F", counter => x"00", valid => '1'), -- Key #3
        2 => (id => x"04", key => x"00000014", counter => x"00", valid => '1'), -- Key #4
        3 => (id => x"FF", key => x"00000000", counter => x"00", valid => '0')  -- Empty slot
    );
    
begin
    -- Main Process: Lookup & Update 
    process(clk, rst)
        variable match_found : std_logic;
        variable match_index : integer range 0 to 3;
    begin
        if rst = '1' then
            key_found <= '0';
            stored_key <= (others => '0');
            stored_counter <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Lookup Operation
            if lookup_en = '1' then
                match_found := '0';
                match_index := 0;
                for i in 0 to 3 loop  
                    if database(i).valid = '1' and database(i).id = lookup_id then
                        match_found := '1';
                        match_index := i;
                    end if;
                end loop;
                
                -- Output results
                if match_found = '1' then
                    key_found <= '1';
                    stored_key <= database(match_index).key;
                    stored_counter <= database(match_index).counter;
                else
                    key_found <= '0';
                    stored_key <= (others => '0');
                    stored_counter <= (others => '0');
                end if;
            end if;
            
            -- Couter Update
            if update_en = '1' then
                for i in 0 to 3 loop
                    if database(i).valid = '1' and database(i).id = update_id then
                        database(i).counter <= update_counter;
                    end if;
                end loop;
            end if;
            
        end if;
    end process;
    
end Behavioral;