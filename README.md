**DIGITAL SYSTEM DESIGN FINAL PROJECT**

*Rolling Car Key System with SPI Communication*
----------------------------------------------

GROUP 1  
Nadira Fayyaza Aisy 2406368933  
Nayla Pramesti Adhina 2406368901  
Hanif Mulia Nugroho 2406369066  

Project Description
----------------------------------------------
In this project, a secure Remote Keyless Entry (RKE) system based on the Rolling Code (Hopping Code) algorithm to avoid replay attacks is implemented. It is made up of a "Key Fob" (Client) and a "Car System" (Server) which communicate to each other using the Serial Peripheral Interface (SPI) protocol. This design is unique in the sense that all signals sent are unique unlike normal fixed-code systems. The car compares the received code with an authoritative set of the future codes called the window and has a high level of security on the vehicle access.

Key Features: 
1. Rolling Code Generation: Generates unique codes with each button press by using a pseudo-random number generator (PRNG) or counter-based logic (OTP).
2. SPI Communication: The communication will use SPI (Master/Slave) protocol to establish a reliable data transmission between the Key module and the Car module.
3. Database Management: Stores a database of paired keys and their up-to-date synchronization counters (Seeds) on the Car side.
4. Resynchronization Window: Allows the car to accept the codes that are a little bit ahead of the counted (processing the scenario when the key is pressed without being close to the car).
5. Status Feedback: Visual feedback (LEDs/ Signals ) of UNLOCKSUCCESS, SYNCERROR or INVALIDKEY.

System Components
1. Key Fob (SPI Master):
   - Produces the following  using the seed/counter.
   - Starts spy transmission when the user presses a button.
2. Car ECU (SPI Slave):
   - The 32-bit/16-bit encrypted command is sent to it by SPI.
   - Validates the Key ID with the authorized database.
   - Verifies whether or not received Rolling Code is within the valid acceptance window.
3. Rolling Algorithm Core:
   - The logic to produce the subsequent valid code sequence is the cryptographic or linear feedback shift register (LFSR).
4. Finite State Machine (FSM):
   - Regulates the flow: IDLE- GENERATECODE- TRANSMIT- WAITACK.







