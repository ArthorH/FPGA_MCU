library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    port (
        op_a    : in  std_logic_vector(7 downto 0); -- Operand A (RegFile or Immediate)
        op_b    : in  std_logic_vector(7 downto 0); -- Operand B (RegFile)
        alu_sel : in  std_logic_vector(3 downto 0); -- Operation Selector
        cin     : in  std_logic;                    -- Carry In (from SREG)
        result  : out std_logic_vector(7 downto 0); -- 8-bit result
        flags   : out std_logic_vector(4 downto 0)  -- Z, C, N, V, H
    );
end entity;

architecture Behavioral of ALU is
    -- Internal signals to handle arithmetic with carry (9 bits)
    signal res_i   : std_logic_vector(7 downto 0);
    signal res_ext : std_logic_vector(8 downto 0);
    
    -- Constants for alu_sel (examples based on manual logic)
    constant ALU_ADC  : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SBC  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_AND  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OR   : std_logic_vector(3 downto 0) := "0011";
    constant ALU_XOR  : std_logic_vector(3 downto 0) := "0100";
    constant ALU_COM  : std_logic_vector(3 downto 0) := "0101";
    constant ALU_NEG  : std_logic_vector(3 downto 0) := "0110";
    constant ALU_MOV_B: std_logic_vector(3 downto 0) := "0111";
    constant ALU_MOV_A: std_logic_vector(3 downto 0) := "1000";

begin
    -- 1. Main Operation Logic using 'with select' 
    with alu_sel select
        res_i <= 
            std_logic_vector(unsigned(op_a) + unsigned(op_b) + (unsigned'("") & cin)) when ALU_ADC,   -- ADC, ADCI 
            std_logic_vector(unsigned(op_a) - unsigned(op_b) - (unsigned'("") & cin)) when ALU_SBC,   -- SBC, SBCI, CP, CPI
            op_a and op_b   when ALU_AND,   -- AND, ANDI 
            op_a or op_b    when ALU_OR,    -- OR, ORI 
            op_a xor op_b   when ALU_XOR,   -- XOR, XORI 
            not op_a        when ALU_COM,   -- COM (1's complement) 
            std_logic_vector(unsigned(not op_a) + 1) when ALU_NEG, -- NEG (2's complement) 
            op_b            when ALU_MOV_B, -- MOV (Pass Through B) 
            op_a            when ALU_MOV_A, -- LDI (Pass Through A) 
            "00000000"      when others;

    result <= res_i;

    -- 2. Extended result for Carry flag calculation 
    res_ext <= std_logic_vector(unsigned('0' & op_a) + unsigned('0' & op_b) + (unsigned'("") & cin)) 
               when alu_sel = ALU_ADC else
               std_logic_vector(unsigned('0' & op_a) - unsigned('0' & op_b) - (unsigned'("") & cin))
               when alu_sel = ALU_SBC else
               '0' & res_i;

    -- 3. Flag Generation
    -- Order: Z (4), C (3), N (2), V (1), H (0) 
    flags(4) <= '1' when res_i = "00000000" else '0'; -- Z (Zero) 
    flags(3) <= res_ext(8);                         -- C (Carry)
    flags(2) <= res_i(7);                           -- N (Negative)
    flags(1) <= (op_a(7) and op_b(7) and (not res_i(7))) or ((not op_a(7)) and (not op_b(7)) and res_i(7)); -- V (Overflow simplification) [cite: 892]
    flags(0) <= (op_a(3) and op_b(3)) or (op_b(3) and (not res_i(3))) or (op_a(3) and (not res_i(3))); -- H (Half Carry simplification) [cite: 891]

end architecture;