library IEEE;
use ieee.std_logic_1164.all;

entity status_register is
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        sreg_we   : in  std_logic;                    -- Write Enable from Control Unit
        alu_flags : in  std_logic_vector(7 downto 0); -- Flags coming from ALU
        sreg_out  : out std_logic_vector(7 downto 0)  -- Current state of flags
    );
end entity;

architecture behavioral of status_register is
    signal sreg_reg : std_logic_vector(7 downto 0) := (others => '0');
begin

    -- Synchronous process to update flags
    process(clk, reset)
    begin
        if reset = '1' then
            sreg_reg <= (others => '0');
        elsif rising_edge(clk) then
            if sreg_we = '1' then
                sreg_reg <= alu_flags;
            end if;
        end if;
    end process;

    sreg_out <= sreg_reg;

end architecture;