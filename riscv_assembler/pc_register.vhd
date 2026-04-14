library ieee;
use ieee.std_logic_1164.all;

entity pc_register is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        enable  : in  std_logic;
        next_pc : in  std_logic_vector(31 downto 0);
        pc_out  : out std_logic_vector(31 downto 0)
    );
end entity pc_register;

architecture behavioral of pc_register is

    signal pc_reg : std_logic_vector(31 downto 0) := (others => '0');

begin

    -- program counter register.
    -- holds the current address, resets to 0x0, and updates to
    -- next PC value when enable

    process(clk)

    begin

        if rising_edge(clk) then

            if reset = '1' then

                pc_reg <= (others => '0');
                
            elsif enable = '1' then
                pc_reg <= next_pc;

            end if;

        end if;

    end process;

    pc_out <= pc_reg;
    
end architecture behavioral;