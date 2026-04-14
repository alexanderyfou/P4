library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;

entity immediate_generator is
    port (
        instruction : in  std_logic_vector(31 downto 0);
        immediate   : out std_logic_vector(31 downto 0)
    );
end entity immediate_generator;

architecture behavioral of immediate_generator is

begin

    process(instruction)

        variable opcode : std_logic_vector(6 downto 0);
        variable imm32  : signed(31 downto 0);

    begin

        -- generating the 32-bit immediate value from the current instruction.
        -- It supports the RISC-V instructions:
        -- I-type, S-type, B-type, U-type, and J-type immediates.

        opcode := instruction(6 downto 0);
        imm32 := (others => '0');

        case opcode is

            -- I-type
            when OP_I_ARITH | OP_LOAD | OP_JALR =>
                imm32 := resize(signed(instruction(31 downto 20)), 32);

            -- S-type
            when OP_STORE =>
                imm32 := resize(signed(instruction(31 downto 25) & instruction(11 downto 7)), 32);

            -- B-type
            when OP_BRANCH =>
                imm32 := resize(signed(instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0' ), 32);

            -- U-type: lui
            when OP_LUI =>
                immediate <= instruction(31 downto 12) & x"000";

            -- U-type: auipc
            when OP_AUIPC =>
                immediate <= instruction(31 downto 12) & x"000";

            -- J-type
            when OP_JAL =>
    imm32 := resize(signed(
        instruction(31) &
        instruction(19 downto 12) &
        instruction(20) &
        instruction(30 downto 21) &
        '0'
    ), 32);
            when others =>
                imm32 := (others => '0');

        end case;

        if opcode /= OP_LUI and opcode /= OP_AUIPC then
            immediate <= std_logic_vector(imm32);

        end if;

    end process;
    
end architecture behavioral;