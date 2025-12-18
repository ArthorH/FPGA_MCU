----------------------------------------------------------------------------------
-- Company: Chrome electronics
-- Engineer: Artem Horiunov
-- 
-- Design Name: Program Counter
-- Module Name: ProgramCounter - Behavioral
-- Project Name: PolyFlop8
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgramCounter is
    Port (
        clk    : in  STD_LOGIC;                    -- System Clock (Active Rising Edge)
        reset  : in  STD_LOGIC;                    -- System Reset (Active High)
        pc_en  : in  STD_LOGIC;                    -- PC Write Enable
        pc_src : in  STD_LOGIC_VECTOR(1 downto 0); -- MUX Selector: 00=Inc, 01=Branch, 10=Jump, 11=Zero
        offset : in  STD_LOGIC_VECTOR(7 downto 0); -- Signed 8-bit offset (k)
        target : in  STD_LOGIC_VECTOR(7 downto 0); -- Absolute 8-bit target address
        pc_out : out STD_LOGIC_VECTOR(7 downto 0)  -- Current instruction address
    );
end ProgramCounter;

architecture Behavioral of ProgramCounter is
    -- Internal registers (8-bit syncronous register)
    signal pc_reg  : unsigned(7 downto 0) := (others => '0');
    signal next_pc : unsigned(7 downto 0);
begin

    -- Ouput to RAM 
    pc_out <= std_logic_vector(pc_reg);

    -------------------------------------------------------
    -- Next Address Logic
    -------------------------------------------------------
    process(pc_reg, pc_src, offset, target)
    begin
        case pc_src is
            when "00" => -- Normal Operation: PC + 1
                next_pc <= pc_reg + 1;

            when "01" => 
                -- Relative Branching: PolyFlop8 wymaga skok w formacie PC + 1 + k
                -- U?ywamy signed, aby umo?liwi? skoki wstecz
                next_pc <= unsigned(signed(pc_reg + 1) + signed(offset));

            when "10" => -- Absolute Jump
                next_pc <= unsigned(target);

            when "11" => -- Hard Reset/Clear: Wymusza 0x00
                next_pc <= (others => '0');

            when others =>
                next_pc <= pc_reg;
        end case;
    end process;

    -------------------------------------------------------
    -- Synchronous Update
    -------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            -- Async reset - if 1 than set to 0x00
            pc_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- PC gets updated only when PC-EN = 1
            if pc_en = '1' then
                pc_reg <= next_pc;
            -- ELSE STALL (hold value)
            end if;
        end if;
    end process;

end Behavioral;