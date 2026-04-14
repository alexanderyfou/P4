-- common_pkg.vhd
-- Shared constants for the RISC-V pipelined processor.
-- Used by: control_unit, alu, execute_stage, and other pipeline stages.

library ieee;
use ieee.std_logic_1164.all;

package common_pkg is

    -- RISC-V Opcode Constants (instruction bits [6:0])
    constant OP_R_TYPE  : std_logic_vector(6 downto 0) := "0110011"; -- R-type ALU
    constant OP_I_ARITH : std_logic_vector(6 downto 0) := "0010011"; -- I-type ALU
    constant OP_LOAD    : std_logic_vector(6 downto 0) := "0000011"; -- Loads
    constant OP_STORE   : std_logic_vector(6 downto 0) := "0100011"; -- Stores
    constant OP_BRANCH  : std_logic_vector(6 downto 0) := "1100011"; -- Branches
    constant OP_JAL     : std_logic_vector(6 downto 0) := "1101111"; -- Jump and Link
    constant OP_JALR    : std_logic_vector(6 downto 0) := "1100111"; -- Jump and Link Register
    constant OP_LUI     : std_logic_vector(6 downto 0) := "0110111"; -- Load Upper Immediate
    constant OP_AUIPC   : std_logic_vector(6 downto 0) := "0010111"; -- Add Upper Imm to PC

    -- ALU Operation Codes (4-bit, used by control_unit -> ALU)
    constant ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_MUL  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_AND  : std_logic_vector(3 downto 0) := "0011";
    constant ALU_OR   : std_logic_vector(3 downto 0) := "0100";
    constant ALU_XOR  : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SLL  : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRL  : std_logic_vector(3 downto 0) := "0111";
    constant ALU_SRA  : std_logic_vector(3 downto 0) := "1000";
    constant ALU_SLT  : std_logic_vector(3 downto 0) := "1001";
    constant ALU_SLTU : std_logic_vector(3 downto 0) := "1010";

    -- ALU Source A mux select
    constant ALU_SRC_A_RS1  : std_logic_vector(1 downto 0) := "00"; -- rs1 data
    constant ALU_SRC_A_PC   : std_logic_vector(1 downto 0) := "01"; -- Program counter
    constant ALU_SRC_A_ZERO : std_logic_vector(1 downto 0) := "10"; -- Zero (for LUI)

    -- Branch funct3 codes (used by branch comparator)
    constant FUNCT3_BEQ  : std_logic_vector(2 downto 0) := "000";
    constant FUNCT3_BNE  : std_logic_vector(2 downto 0) := "001";
    constant FUNCT3_BLT  : std_logic_vector(2 downto 0) := "100";
    constant FUNCT3_BGE  : std_logic_vector(2 downto 0) := "101";
    constant FUNCT3_BLTU : std_logic_vector(2 downto 0) := "110";
    constant FUNCT3_BGEU : std_logic_vector(2 downto 0) := "111";

end package common_pkg;
