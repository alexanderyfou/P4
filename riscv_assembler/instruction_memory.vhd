library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_memory is
    port (
        address     : in  std_logic_vector(31 downto 0);
        instruction : out std_logic_vector(31 downto 0)
    );
end entity instruction_memory;

architecture behavioral of instruction_memory is

    -- instruction memory for the processor.
    -- returns the 32-bit instruction stored at the address at the PC and
    -- can support up to 1024 instructions.

    type mem_array is array (0 to 1023) of std_logic_vector(31 downto 0);

    signal mem : mem_array := (
        0 => x"00500093",  -- addi x1, x0, 5
        1 => x"00700113",  -- addi x2, x0, 7
        2 => x"00000013",  -- nop   (addi x0, x0, 0)
        3 => x"00000013",  -- nop
        4 => x"00000013",  -- nop
        5 => x"002081B3",  -- add x3, x1, x2
        6 => x"0000006F",  -- jal x0, 0
        others => (others => '0')
    );

begin



    instruction <= mem(to_integer(unsigned(address(11 downto 2))));

end architecture behavioral;