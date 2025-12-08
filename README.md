**DIGITAL SYSTEM DESIGN FINAL PROJECT**

*Rolling Car Key System with SPI Communication*
----------------------------------------------

GROUP 1  
Nadira Fayyaza Aisy 2406368933  
Nayla Pramesti Adhina 2406368901  
Hanif Mulia Nugroho 2406369066  

Project Description
----------------------------------------------
This project is concerned with designing and development of a safe Remote Keyless Entry (RKE) system on a car. The system has a mechanism of Rolling Code which is One-Time password (OTP) which eliminates the replay attack. The system will be made up of a Key (Transmitter) and a Car (Receiver) that communicate through the protocol of the Serial Peripheral Interface (SPI).

The system is secure because it uses a counter, which increases with each button press, and it also produces a unique hash (OTP) using a shared secret key. The car authenticates the signal through the validation of User ID, computation of the anticipated OTP, and verification of a received counter in a valid synchronization window.

Key Features : 
1. Rolling Code Security: This type of security uses a non-linear algorithm (XOR, rotate bits, constants) to make each transmission have a unique OTP.
2. Communication: SPI Master (Key) and SPI Slave (Car) Custom implementation of SPI Master and SPI Slave to ensure reliable transfer of data.
3. Synchronization Window: The receiver tolerates counters in a certain range (Window = 10) to deal with desynchronization to deter replay attacks.
4. Database Management: The Car has a database of authorized UserID, Secret Key and last valid Counter values.
5. Finite State Machine (FSM): Coordinates complicated control streams of sequence of packet transmission and validation code.

System Components : 
1. Key (Client):
   - Debounces user button input.
   - Maintains an internal counter and secret key.
   - Acts as the SPI Master to send three packets: User ID, Counter Value, and OTP.
  
2. Car (Server):
   - Acts as the SPI Slave.
   - Lookups credentials in Car_Database.
   - Validates the received OTP against an internally calculated OTP.
   - Controls physical actuators (Door_Lock and Alarm).
  
3. OTP Generator :
   - A cryptographic module shared by both entities to generate the 32-bit hash.

Design Structure
The system design will be modular with the separation of communication, logic, storage. The main elements that are converted to the VHDL code are as stated below:

1. OTP_Generator (Entity)
The key security engine that calculates a 32-bit One-Time Password using a Counter and a Secret Key. It makes use of bitwise operation and a golden ratio constant which facilitates diffusion of data.

VHDL Code - OTP_Generator 
```vhdl
process(Counter, Secret_Key)
    variable temp : unsigned(31 downto 0);
begin
    --XOR Counter with Secret_Key (initial mixing)
    temp := unsigned(Counter) xor unsigned(Secret_Key);
    
    -- Non-linear diffusion (add rotated version of itself)
    temp := temp + (temp rol 3);
    
    --Add golden ratio constant (break patterns)
    temp := temp + x"9E37";
    
    --Final bit spreading (rotate left 7 bits)
    temp := temp rol 7;
    
    OTP_Result <= std_logic_vector(temp);
end process;
```

Type of Design Behavioral Style.
It's a pseudo-random generation process. Just a slight modification in the Counter will cause a significant alteration in the OTP, which will not allow attackers to predict the next code .

2. Car_Database (Entity)
A component of the Car that contains credentials is a database. It enables the system to search a Secret Key using User ID and modify the stored Counter upon successful unlocking.

VHDL Code - Car_Database :
```vhdl
type key_record is record
    id      : std_logic_vector(7 downto 0);
    key     : std_logic_vector(31 downto 0);
    counter : std_logic_vector(7 downto 0);
    valid   : std_logic;
end record;

type db_array is array(0 to 3) of key_record;

--Database initialization
signal database : db_array := (
    0 => (id => x"02", key => x"0000000B", counter => x"00", valid => '1'), 
    1 => (id => x"03", key => x"0000000F", counter => x"00", valid => '1'), 
    -- ...
);
```
Type of Design: Behavioral Style.
This is the component that serves as the system memory. It helps in lookup operations to get the keys to verify and update operations to save the new counter value to avoid the use of old codes again.

3. Key_FSM (Finite State Machine)
This FSM regulates the sequence of transmission of the Key. It makes sure that data is transmitted in the particular sequence that is needed by the protocol.

VHDL Code - Key_FSM 
```vhdl
type state_type is (
    ST_IDLE,
    ST_START_ID, ST_WAIT_BUSY_ID, ST_WAIT_DONE_ID, ST_GAP_1,
    ST_START_CNT, ST_WAIT_BUSY_CNT, ST_WAIT_DONE_CNT, ST_GAP_2,
    ST_START_OTP, ST_WAIT_BUSY_OTP, ST_WAIT_DONE_OTP,
    ST_UPDATE
);
```
Type of Design Finite State Machine (FSM).
FSM passes through three stages of transmission. It transmits User ID (Packet 1), Counter (Packet 2) and lastly OTP (Packet 3). Then it causes a counter to be increased inwardly.

4. Car_FSM (Finite State Machine)
Deals with the logic of the physical response of the Car. Depending on the results of the validation it will open the door or activate the alarm.

VHDL Code - Car_FSM
```vhdl
case current_state is
    when ST_IDLE =>
        if Remote_Trigger = '1' then
            next_state <= ST_CHECK;
        end if;
    when ST_CHECK =>
        Check_Enable <= '1';
        if Code_Is_Correct = '1' then 
            next_state <= ST_UPDATE; -- Unlock sequence
        else
            next_state <= ST_ALARM;  -- Invalid code sequence
        end if;
    when ST_OPEN =>
        Door_Open <= '1';
        next_state <= ST_OPEN;
end case;
```
Type of Design Finite State Machine (FSM).
The state machine is waiting to be triggered by the SPI receiver. On receipt of data it is transferred to STCHECK. On high CodeIsCorrect signal (OTP matches) the door is unlocked, and the AlarmSiren is switched on.

5. Car (Top-Level Entity)
This is the highest level element, which mounts SPI Slave, Database, OTP Generator and Control FSM into the overall receiver system.

VHDL Code - Car
```vhdl
--Validates if the received counter is within the allowed window
process(Reg_Counter, db_stored_counter)
begin
    if (recv_cnt >= stored_cnt) and (recv_cnt <= upper_limit) then
        Counter_Valid <= '1';
    else
        Counter_Valid <= '0';
    end if;
end process;

--Validates the OTP
process(Reg_OTP_Code, Expected_OTP, Counter_Valid, db_key_found)
begin
    if (Reg_OTP_Code = Expected_OTP) and (Counter_Valid = '1') and (db_key_found = '1') then
        Match_Flag <= '1';
    else
        Match_Flag <= '0';
    end if;
end process;
```
Design Type Structural and Behavioral Mixed.
This entity links the SPISlave (which receives the 3 packets) and the OTPGenerator (which computes the code that is expected). It has the critical logic which compares the received OTP with the calculated OTP and checks that the counter is fresh.
