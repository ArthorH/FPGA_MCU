----------------------------------------------------------------------------------
-- Module Name: RegFile - Behavioral
-- Project Name: PolyFlop8
-- Description: Multi-ported Static RAM block (8 x 8-bit registers).
--              Supports two asynchronous reads and one synchronous write.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Potrzebne do konwersji adresów na integery

entity RegFile is
    Port (
        clk     : in  STD_LOGIC;                    -- System Clock
        we      : in  STD_LOGIC;                    -- Write Enable 
        addr_a  : in  STD_LOGIC_VECTOR(2 downto 0); -- Read Address A (Rs)
        addr_b  : in  STD_LOGIC_VECTOR(2 downto 0); -- Read Address B (Rd)
        addr_w  : in  STD_LOGIC_VECTOR(2 downto 0); -- Write Address (Rd)
        data_in : in  STD_LOGIC_VECTOR(7 downto 0); -- Data from ALU/RAM 
        data_a  : out STD_LOGIC_VECTOR(7 downto 0); -- Output Port A
        data_b  : out STD_LOGIC_VECTOR(7 downto 0)  -- Output Port B
    );
end RegFile;

architecture Behavioral of RegFile is
    type reg_array is array (0 to 7) of std_logic_vector(7 downto 0);
    signal registers : reg_array := (others => (others => '0')); -- Inicjalizacja rejestrów zerami
begin

    -------------------------------------------------------
    -- ASYNCHRONOUS READ (Combinational Logic)
    -------------------------------------------------------
    -- Zmiany na adresach addr_a/b natychmiast zmieniaj? wyj?cia.
    -- Adresy nie mog? by? rejestrowane, aby zachowa? model single-cycle.
    data_a <= registers(to_integer(unsigned(addr_a)));
    data_b <= registers(to_integer(unsigned(addr_b)));

    -------------------------------------------------------
    -- SYNCHRONOUS WRITE (Sequential Logic)
    -------------------------------------------------------
    -- Zapis nast?puje na zboczu narastaj?cym zegara clk, gdy we = '1'.
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                registers(to_integer(unsigned(addr_w))) <= data_in;
            end if;
        end if;
    end process;

end Behavioral;