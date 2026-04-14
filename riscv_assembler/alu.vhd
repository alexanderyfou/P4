-- alu.vhd
-- 32-bit ALU for the RISC-V pipelined processor.
-- Supports all RV32I integer operations + MUL from RV32M.
-- Purely combinational: no clock, outputs update immediately.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;

entity alu is
    port (
        operand_a : in  std_logic_vector(31 downto 0);  -- first operand
        operand_b : in  std_logic_vector(31 downto 0);  -- second operand
        alu_op    : in  std_logic_vector(3 downto 0);   -- operation select
        result    : out std_logic_vector(31 downto 0);  -- computation result
        zero      : out std_logic                       -- '1' when result = 0
    );
end entity alu;

architecture behavioral of alu is
    signal alu_result : std_logic_vector(31 downto 0);
begin

    process(operand_a, operand_b, alu_op)
        variable shift_amt  : natural;
        variable mul_result : signed(63 downto 0);
    begin
        -- shift amount is always the lower 5 bits of operand B
        shift_amt := to_integer(unsigned(operand_b(4 downto 0)));
        alu_result <= (others => '0');

        case alu_op is
            when ALU_ADD =>  -- add / addi / address calc
                alu_result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));

            when ALU_SUB =>  -- sub
                alu_result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b));

            when ALU_MUL =>  -- mul (RV32M), lower 32 bits
                mul_result := signed(operand_a) * signed(operand_b);
                alu_result <= std_logic_vector(mul_result(31 downto 0));

            when ALU_AND =>  -- and / andi
                alu_result <= operand_a and operand_b;

            when ALU_OR =>   -- or / ori
                alu_result <= operand_a or operand_b;

            when ALU_XOR =>  -- xor / xori
                alu_result <= operand_a xor operand_b;

            when ALU_SLL =>  -- sll / slli
                alu_result <= std_logic_vector(shift_left(unsigned(operand_a), shift_amt));

            when ALU_SRL =>  -- srl / srli (zero-fill)
                alu_result <= std_logic_vector(shift_right(unsigned(operand_a), shift_amt));

            when ALU_SRA =>  -- sra / srai (sign-extends)
                alu_result <= std_logic_vector(shift_right(signed(operand_a), shift_amt));

            when ALU_SLT =>  -- slt / slti (signed compare)
                if signed(operand_a) < signed(operand_b) then
                    alu_result <= x"00000001";
                else
                    alu_result <= x"00000000";
                end if;

            when ALU_SLTU => -- sltu / sltiu (unsigned compare)
                if unsigned(operand_a) < unsigned(operand_b) then
                    alu_result <= x"00000001";
                else
                    alu_result <= x"00000000";
                end if;

            when others =>
                alu_result <= (others => '0');
        end case;
    end process;

    result <= alu_result;
    zero   <= '1' when alu_result = x"00000000" else '0';

end architecture behavioral;
