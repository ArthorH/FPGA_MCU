----------------------------------------------------------------------------------
-- Company: Chrome electronics
-- Engineer: Artem Horiunov
-- Create Date: 27.11.2025
-- Design Name: Memory Controller
-- Project Name: PolyFlop8
-- Target Devices: Artix7 XC7A35T-1CPG236C
-- Description: Data RAM Controller (256-byte memory)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity Memory is
    Port (
        reset : in STD_LOGIC;            -- reset state
        clk   : in STD_LOGIC;           -- synchronous memory clock
        mem_we : in STD_LOGIC;           -- Write Enable from Control Unit
        addr_mode : in STD_LOGIC;        -- 0=Direct, 1=Indirect
        imm_addr  : in STD_LOGIC_VECTOR(7 downto 0);   -- Immediate address from IR
        ptr_addr : in STD_LOGIC_VECTOR(7 downto 0);    -- Pointer address from register
        data_w : in STD_LOGIC_VECTOR(7 downto 0);      -- Data to write
        data_r : out STD_LOGIC_VECTOR(7 downto 0)      -- Data read output
    );
end Memory;

architecture Behavioral of Memory is
    -- 256-byte Data RAM
    type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
    signal ram_array : ram_t := (
        others => (others => '0')  -- zero ram when starting
    );
    
    signal selected_addr : std_logic_vector(7 downto 0);
    
begin
    -- Indirect or direct mode selection. 
    process(addr_mode, imm_addr, ptr_addr)
    begin
        case addr_mode is
            when '0' =>    -- Direct addressing (LDS/STS)
                selected_addr <= imm_addr;
            when '1' =>    -- Indirect addressing (LD/ST via X-pointer)
                selected_addr <= ptr_addr;
            when others =>
                selected_addr <= (others => '0');
        end case;
    end process;
    
    -- Synchronous RAM process (as per FPGA block RAM requirements)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- RAM is in reset state... outputs are 0
                data_r <= (others => '0');
            else
                -- Read operation: output data at selected address
                -- (synchronous read - takes 1 clock cycle)
                data_r <= ram_array(to_integer(unsigned(selected_addr)));
                
                -- Write operation: write data to selected address
                if mem_we = '1' then
                    ram_array(to_integer(unsigned(selected_addr))) <= data_w;
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;