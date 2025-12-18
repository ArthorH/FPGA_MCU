library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CPU is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        gpio_o : out std_logic_vector(7 downto 0) -- Output port for OUTP instruction
    );
end entity;

architecture structural of CPU is

    -- Internal Signals for Interconnection
    signal s_pc_out   : std_logic_vector(7 downto 0);
    signal s_rom_data : std_logic_vector(15 downto 0);
    signal s_ir_opcode : std_logic_vector(7 downto 0);
    signal s_ir_arg    : std_logic_vector(7 downto 0);
    
    -- Control Signals
    signal s_pc_en    : std_logic;
    signal s_pc_src   : std_logic_vector(1 downto 0);
    signal s_ir_en    : std_logic;
    signal s_reg_we   : std_logic;
    signal s_alu_sel  : std_logic_vector(3 downto 0);
    signal s_sreg_we  : std_logic;
    signal s_gpio_we  : std_logic;
    
    -- Data Path Signals
    signal s_reg_data_a : std_logic_vector(7 downto 0);
    signal s_reg_data_b : std_logic_vector(7 downto 0);
    signal s_alu_result : std_logic_vector(7 downto 0);
    signal s_alu_flags  : std_logic_vector(4 downto 0); -- Z, C, N, V, H
    signal s_sreg_out   : std_logic_vector(7 downto 0);
    signal s_ram_data_r : std_logic_vector(7 downto 0);
    
    -- Muxed Data for RegFile Input
    signal s_reg_data_in : std_logic_vector(7 downto 0);

begin

    -- 1. Program Counter
    PC_UNIT : entity work.ProgramCounter
        port map (
            clk    => clk,
            reset  => reset,
            pc_en  => s_pc_en,
            pc_src => s_pc_src,
            offset => s_ir_arg,    -- Used for Branch
            target => s_ir_arg,    -- Used for Jump
            pc_out => s_pc_out
        );

    -- 2. Program ROM
    ROM_UNIT : entity work.program_rom
        port map (
            address  => s_pc_out,
            data_out => s_rom_data
        );

    -- 3. Instruction Register
    IR_UNIT : entity work.instruction_register
        port map (
            clk      => clk,
            reset    => reset,
            ir_en    => s_ir_en,
            data_in  => s_rom_data,
            opcode   => s_ir_opcode,
            argument => s_ir_arg
        );

    -- 4. Control Unit
    CU_UNIT : entity work.control_unit
        port map (
            clk     => clk,
            reset   => reset,
            opcode  => s_ir_opcode,
            flags   => s_sreg_out,
            pc_en   => s_pc_en,
            pc_src  => s_pc_src,
            ir_en   => s_ir_en,
            reg_we  => s_reg_we,
            alu_sel => s_alu_sel,
            sreg_we => s_sreg_we,
            gpio_we => s_gpio_we
        );

    -- 5. Register File 
    -- Logic: Rs/Rd addresses are extracted from instruction bits or arg
    REG_UNIT : entity work.RegFile
        port map (
            clk     => clk,
            we      => s_reg_we,
            addr_a  => s_ir_arg(2 downto 0), -- Example: Lower bits of arg as Rs
            addr_b  => s_ir_arg(5 downto 3), -- Example: Middle bits of arg as Rd
            addr_w  => s_ir_arg(5 downto 3), -- Rd for writing back
            data_in => s_reg_data_in,
            data_a  => s_reg_data_a,
            data_b  => s_reg_data_b
        );

    -- 6. ALU
    ALU_UNIT : entity work.ALU
        port map (
            op_a    => s_reg_data_a,
            op_b    => s_reg_data_b,
            alu_sel => s_alu_sel,
            cin     => s_sreg_out(3), -- Mapping 'C' flag from SREG to ALU Carry-In
            result  => s_alu_result,
            flags   => s_alu_flags
        );

    -- 7. Status Register
    SREG_UNIT : entity work.status_register
        port map (
            clk       => clk,
            reset     => reset,
            sreg_we   => s_sreg_we,
            alu_flags  => "000" & s_alu_flags, -- Pad 5-bit flags to 8-bit SREG
            sreg_out  => s_sreg_out
        );

    -- 8. Data Memory (RAM)
    RAM_UNIT : entity work.Memory
        port map (
            reset     => reset,
            clk       => clk,
            mem_we    => '0',            -- Logic for STS/ST instructions
            addr_mode => '0',            -- 0: Direct, 1: Indirect
            imm_addr  => s_ir_arg,
            ptr_addr  => s_reg_data_a,   -- Register acting as pointer
            data_w    => s_reg_data_b,
            data_r    => s_ram_data_r
        );

    -- 9. GPIO Logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                gpio_o <= (others => '0');
            elsif s_gpio_we = '1' then
                gpio_o <= s_ir_arg; -- Logic for OUTP: argument value to GPIO
            end if;
        end if;
    end process;

    -- Multiplexer for RegFile Data Input
    -- Selection logic depends on opcode: LDI (Immediate) vs ALU Result vs RAM
    s_reg_data_in <= s_ir_arg    when s_ir_opcode = x"04" else -- C_LDI
                     s_ram_data_r when s_ir_opcode = x"06" else -- Example LD
                     s_alu_result;

end architecture;