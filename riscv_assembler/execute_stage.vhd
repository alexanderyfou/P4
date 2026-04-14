-- execute_stage.vhd
-- Execute (EX) stage of the RISC-V pipelined processor.
--
-- Combines all combinational logic in the EX stage:
--   1. ALU input muxes (select operands based on control signals)
--   2. ALU instance (arithmetic/logic)
--   3. Branch comparator (beq/bne/blt/bge/bltu/bgeu)
--   4. Branch/jump target address computation
--   5. PC+4 adder for JAL/JALR link address
--   6. Output muxes
--
-- Outputs feed into the EX/MEM pipeline register (Person 3).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;

entity execute_stage is
    port (
        -- inputs from ID/EX register
        pc        : in std_logic_vector(31 downto 0);
        rs1_data  : in std_logic_vector(31 downto 0);
        rs2_data  : in std_logic_vector(31 downto 0);
        immediate : in std_logic_vector(31 downto 0);
        funct3    : in std_logic_vector(2 downto 0);  -- for branch comparison type

        -- control from ID/EX register
        alu_op    : in std_logic_vector(3 downto 0);
        alu_src_a : in std_logic_vector(1 downto 0);
        alu_src_b : in std_logic;
        branch    : in std_logic;
        jump      : in std_logic;
        is_jalr   : in std_logic;

        -- outputs to EX/MEM register (Person 3)
        alu_result    : out std_logic_vector(31 downto 0); -- ALU output or PC+4 for jumps
        branch_target : out std_logic_vector(31 downto 0); -- target address for branches/jumps
        branch_taken  : out std_logic;                     -- '1' to redirect PC
        rs2_data_out  : out std_logic_vector(31 downto 0)  -- forwarded rs2 for stores
    );
end entity execute_stage;

architecture structural of execute_stage is
    signal alu_a      : std_logic_vector(31 downto 0);
    signal alu_b      : std_logic_vector(31 downto 0);
    signal alu_out    : std_logic_vector(31 downto 0);
    signal alu_zero   : std_logic;
    signal pc_plus_4  : std_logic_vector(31 downto 0);
    signal branch_cond : std_logic;
begin

    -- ALU input A mux
    alu_a <= rs1_data          when alu_src_a = ALU_SRC_A_RS1  else  -- most instructions
             pc                when alu_src_a = ALU_SRC_A_PC   else  -- AUIPC
             (others => '0');  -- LUI: 0 + imm = imm

    -- ALU input B mux
    alu_b <= rs2_data  when alu_src_b = '0' else  -- R-type
             immediate;                            -- I/S/U-type

    -- ALU instance
    alu_inst : entity work.alu
        port map (
            operand_a => alu_a,
            operand_b => alu_b,
            alu_op    => alu_op,
            result    => alu_out,
            zero      => alu_zero
        );

    -- PC+4 for JAL/JALR link address
    pc_plus_4 <= std_logic_vector(unsigned(pc) + 4);

    -- branch/jump target address
    -- Branch & JAL: PC + immediate (imm is already a byte offset, no shift)
    -- JALR: (rs1 + immediate) with bit 0 cleared per RISC-V spec
    process(pc, rs1_data, immediate, is_jalr)
        variable jalr_target : std_logic_vector(31 downto 0);
    begin
        if is_jalr = '1' then
            jalr_target := std_logic_vector(unsigned(rs1_data) + unsigned(immediate));
            jalr_target(0) := '0';
            branch_target <= jalr_target;
        else
            branch_target <= std_logic_vector(unsigned(pc) + unsigned(immediate));
        end if;
    end process;

    -- branch comparator: evaluates condition based on funct3
    process(rs1_data, rs2_data, funct3, branch)
    begin
        branch_cond <= '0';

        if branch = '1' then
            case funct3 is
                when FUNCT3_BEQ =>
                    if rs1_data = rs2_data then
                        branch_cond <= '1';
                    end if;
                when FUNCT3_BNE =>
                    if rs1_data /= rs2_data then
                        branch_cond <= '1';
                    end if;
                when FUNCT3_BLT =>
                    if signed(rs1_data) < signed(rs2_data) then
                        branch_cond <= '1';
                    end if;
                when FUNCT3_BGE =>
                    if signed(rs1_data) >= signed(rs2_data) then
                        branch_cond <= '1';
                    end if;
                when FUNCT3_BLTU =>
                    if unsigned(rs1_data) < unsigned(rs2_data) then
                        branch_cond <= '1';
                    end if;
                when FUNCT3_BGEU =>
                    if unsigned(rs1_data) >= unsigned(rs2_data) then
                        branch_cond <= '1';
                    end if;
                when others =>
                    branch_cond <= '0';
            end case;
        end if;
    end process;

    -- redirect PC on jump or branch taken
    branch_taken <= jump or branch_cond;

    -- output mux: JAL/JALR write PC+4 to rd, everything else uses ALU
    alu_result <= pc_plus_4 when jump = '1' else alu_out;

    -- pass rs2 through for store instructions
    rs2_data_out <= rs2_data;

end architecture structural;
