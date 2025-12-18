library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        
        -- Inputs from other blocks
        opcode   : in  std_logic_vector(7 downto 0); -- From IR high byte
        flags    : in  std_logic_vector(7 downto 0); -- From SREG
        
        -- Control signals to PC
        pc_en    : out std_logic;
        pc_src   : out std_logic_vector(1 downto 0); -- 00: Inc, 01: Branch/Jump
        
        -- Control signals to other blocks
        ir_en    : out std_logic;                    -- Instruction Register Enable
        reg_we   : out std_logic;                    -- RegFile Write Enable
        alu_sel  : out std_logic_vector(3 downto 0); -- ALU Op Selector
        sreg_we  : out std_logic;                    -- Status Register Write Enable
        gpio_we  : out std_logic                     -- GPIO Output Enable
    );
end entity;

architecture behavioral of control_unit is
    -- Define states as per Lab 7 Manual
    type state_t is (S_FETCH, S_EX);
    signal current_state, next_state : state_t;

    -- Opcode Constants (from Lab 7/8/10)
    constant C_NOP  : std_logic_vector(7 downto 0) := x"00";
    constant C_OUTP : std_logic_vector(7 downto 0) := x"01";
    constant C_BZ   : std_logic_vector(7 downto 0) := x"02";
    constant C_B    : std_logic_vector(7 downto 0) := x"03";
    constant C_LDI  : std_logic_vector(7 downto 0) := x"04";
    constant C_ADD  : std_logic_vector(7 downto 0) := x"05";

    -- Alias for flags (Z is typically bit 1 or 4 depending on lab)
    alias flag_z : std_logic is flags(1); 

begin

    -- 1. State Register (Synchronous)
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= S_FETCH;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- 2. Next State and Output Logic (Combinational)
    process(current_state, opcode, flag_z)
    begin
        -- Default values (prevent latches)
        next_state <= S_FETCH;
        pc_en      <= '0';
        pc_src     <= "00";
        ir_en      <= '0';
        reg_we     <= '0';
        alu_sel    <= "0000";
        sreg_we    <= '0';
        gpio_we    <= '0';

        case current_state is
            when S_FETCH =>
                ir_en      <= '1';      -- Capture instruction from ROM
                pc_en      <= '1';      -- Increment PC for next fetch
                pc_src     <= "00";     -- Standard Increment (PC + 1)
                next_state <= S_EX;

            when S_EX =>
                next_state <= S_FETCH;  -- Always return to fetch after execution
                
                -- Decode Opcode
                case opcode is
                    when C_NOP =>
                        null;           -- Do nothing

                    when C_OUTP =>
                        gpio_we <= '1'; -- Trigger GPIO write

                    when C_B =>
                        pc_en   <= '1'; 
                        pc_src  <= "01"; -- Absolute jump (Load arg into PC)

                    when C_BZ =>
                        if flag_z = '1' then
                            pc_en  <= '1';
                            pc_src <= "01"; -- Branch if Zero
                        end if;

                    when C_LDI =>
                        reg_we <= '1';  -- Write immediate value to RegFile

                    when C_ADD =>
                        alu_sel <= "0000"; -- ADC/ADD operation
                        reg_we  <= '1';    -- Write result back
                        sreg_we <= '1';    -- Update status flags

                    when others =>
                        null;
                end case;
        end case;
    end process;

end architecture;