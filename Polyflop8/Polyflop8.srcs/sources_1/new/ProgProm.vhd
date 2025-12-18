library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity program_rom is
    port (
        address : in  std_logic_vector(7 downto 0); -- From Program Counter (PC)
        data_out : out std_logic_vector(15 downto 0) -- To Instruction Register (IR)
    );
end entity;

architecture behavioral of program_rom is
    -- 1. Define the ROM Type (from Lab 7, Page 1)
    type rom_t is array (0 to 31) of std_logic_vector(15 downto 0);
    
    -- 2. Define Opcode Constants (from Lab 7/8)
    constant C_NOP  : std_logic_vector(7 downto 0) := x"00";
    constant C_OUTP : std_logic_vector(7 downto 0) := x"01";
    constant C_BZ   : std_logic_vector(7 downto 0) := x"02";
    constant C_B    : std_logic_vector(7 downto 0) := x"03";
    constant C_LDI  : std_logic_vector(7 downto 0) := x"04"; -- Example LDI code

    -- 3. Initialize the ROM with the program code
    constant ROM : rom_t := (
        0      => C_OUTP & x"FF", -- Write 0xFF to GPIO
        1      => C_OUTP & x"55", -- Write 0x55 to GPIO
        2      => C_LDI  & x"AA", -- Load 0xAA into a register (if implemented)
        3      => C_BZ   & x"02", -- Branch to address 0x02 if Zero flag is set
        4      => C_B    & x"00", -- Jump back to the start (address 0x00)
        others => C_NOP  & x"00"  -- Fill remaining space with NOPs
    );

begin
    -- Asynchronous read: Data is available as soon as the address changes
    -- Note: We convert the 8-bit PC address to an integer to index the array
    data_out <= ROM(to_integer(unsigned(address(4 downto 0))));

end architecture;