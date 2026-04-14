library ieee;
use ieee.std_logic_1164.all;

entity if_id_register is
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        stall     : in  std_logic;
        flush     : in  std_logic;
        pc_in     : in  std_logic_vector(31 downto 0);
        instr_in  : in  std_logic_vector(31 downto 0);
        
        pc_out    : out std_logic_vector(31 downto 0);
        instr_out : out std_logic_vector(31 downto 0)
    );
end entity if_id_register;


architecture behavioral of if_id_register is

begin

    -- Storing the fetched instruction and its PC between the fetch and decode
    -- stages, and has stall and flush control for pipeline hazards.

    process(clk)

    begin

        if rising_edge(clk) then

            if reset = '1' then
                pc_out    <= (others => '0');
                instr_out <= (others => '0');

            elsif flush = '1' then
                pc_out    <= (others => '0');
                instr_out <= (others => '0');

            elsif stall = '0' then
                pc_out    <= pc_in;
                instr_out <= instr_in;

            end if;

        end if;

    end process;
end architecture behavioral;