-- control_unit.vhd
-- Main control signal decoder for the RISC-V pipelined processor.
--
-- Combinational unit placed in the ID stage. Takes opcode/funct3/funct7
-- from the instruction in IF/ID and generates all control signals that
-- flow into the ID/EX pipeline register.
--
-- Signals are grouped by the stage that uses them:
--   EX:  alu_op, alu_src_a, alu_src_b
--   MEM: branch, jump, is_jalr, mem_read, mem_write
--   WB:  reg_write, mem_to_reg

library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

entity control_unit is
    port (
        -- instruction fields from IF/ID
        opcode : in std_logic_vector(6 downto 0);  -- instr[6:0]
        funct3 : in std_logic_vector(2 downto 0);  -- instr[14:12]
        funct7 : in std_logic_vector(6 downto 0);  -- instr[31:25]

        -- EX stage control
        alu_op    : out std_logic_vector(3 downto 0);  -- ALU operation
        alu_src_a : out std_logic_vector(1 downto 0);  -- ALU input A: 00=rs1, 01=PC, 10=zero
        alu_src_b : out std_logic;                     -- ALU input B: 0=rs2, 1=immediate

        -- MEM stage control
        branch    : out std_logic;  -- conditional branch
        jump      : out std_logic;  -- unconditional jump (JAL/JALR)
        is_jalr   : out std_logic;  -- JALR specifically (target = rs1+imm)
        mem_read  : out std_logic;  -- read from data memory
        mem_write : out std_logic;  -- write to data memory

        -- WB stage control
        reg_write  : out std_logic; -- write to register file
        mem_to_reg : out std_logic  -- 0=ALU result, 1=memory data
    );
end entity control_unit;

architecture behavioral of control_unit is
begin

    process(opcode, funct3, funct7)
    begin
        -- defaults: everything inactive (NOP)
        alu_op     <= ALU_ADD;
        alu_src_a  <= ALU_SRC_A_RS1;
        alu_src_b  <= '0';
        branch     <= '0';
        jump       <= '0';
        is_jalr    <= '0';
        mem_read   <= '0';
        mem_write  <= '0';
        reg_write  <= '0';
        mem_to_reg <= '0';

        case opcode is

            -- R-TYPE: add, sub, mul, and, or, xor, sll, srl, sra, slt, sltu
            -- ALU operates on rs1 and rs2, result written to rd
            when OP_R_TYPE =>
                alu_src_b <= '0';   -- rs2
                reg_write <= '1';

                case funct3 is
                    when "000" =>
                        if    funct7 = "0100000" then alu_op <= ALU_SUB;
                        elsif funct7 = "0000001" then alu_op <= ALU_MUL;
                        else                          alu_op <= ALU_ADD;
                        end if;
                    when "001" => alu_op <= ALU_SLL;
                    when "010" => alu_op <= ALU_SLT;
                    when "011" => alu_op <= ALU_SLTU;
                    when "100" => alu_op <= ALU_XOR;
                    when "101" =>
                        if funct7 = "0100000" then alu_op <= ALU_SRA;
                        else                       alu_op <= ALU_SRL;
                        end if;
                    when "110" => alu_op <= ALU_OR;
                    when "111" => alu_op <= ALU_AND;
                    when others => alu_op <= ALU_ADD;
                end case;

            -- I-TYPE ARITHMETIC: addi, xori, ori, andi, slti, sltiu, slli, srli, srai
            -- ALU operates on rs1 and immediate
            -- For shifts, imm[4:0] = shift amount, imm[11:5] acts like funct7
            when OP_I_ARITH =>
                alu_src_b <= '1';   -- immediate
                reg_write <= '1';

                case funct3 is
                    when "000" => alu_op <= ALU_ADD;   -- addi
                    when "001" => alu_op <= ALU_SLL;   -- slli
                    when "010" => alu_op <= ALU_SLT;   -- slti
                    when "011" => alu_op <= ALU_SLTU;  -- sltiu
                    when "100" => alu_op <= ALU_XOR;   -- xori
                    when "101" =>                      -- srli / srai
                        if funct7 = "0100000" then alu_op <= ALU_SRA;
                        else                       alu_op <= ALU_SRL;
                        end if;
                    when "110" => alu_op <= ALU_OR;    -- ori
                    when "111" => alu_op <= ALU_AND;   -- andi
                    when others => alu_op <= ALU_ADD;
                end case;

            -- LOAD: lb, lh, lw, lbu, lhu
            -- address = rs1 + imm, data read goes to rd
            -- funct3 picks byte/half/word (handled by MEM stage)
            when OP_LOAD =>
                alu_src_b  <= '1';
                alu_op     <= ALU_ADD;
                reg_write  <= '1';
                mem_read   <= '1';
                mem_to_reg <= '1';

            -- STORE: sb, sh, sw
            -- address = rs1 + imm, rs2 data written to memory
            when OP_STORE =>
                alu_src_b <= '1';
                alu_op    <= ALU_ADD;
                mem_write <= '1';

            -- BRANCH: beq, bne, blt, bge, bltu, bgeu
            -- condition checked by branch comparator in execute_stage
            -- target = PC + imm (computed in execute_stage)
            when OP_BRANCH =>
                branch <= '1';

            -- JAL: rd = PC+4, PC = PC + imm
            when OP_JAL =>
                jump      <= '1';
                reg_write <= '1';

            -- JALR: rd = PC+4, PC = (rs1 + imm) & ~1
            when OP_JALR =>
                jump      <= '1';
                is_jalr   <= '1';
                reg_write <= '1';
                alu_src_b <= '1';

            -- LUI: rd = imm (imm already shifted left 12 by imm generator)
            -- we compute 0 + imm = imm
            when OP_LUI =>
                alu_src_a <= ALU_SRC_A_ZERO;
                alu_src_b <= '1';
                alu_op    <= ALU_ADD;
                reg_write <= '1';

            -- AUIPC: rd = PC + imm (imm already shifted left 12)
            when OP_AUIPC =>
                alu_src_a <= ALU_SRC_A_PC;
                alu_src_b <= '1';
                alu_op    <= ALU_ADD;
                reg_write <= '1';

            when others =>
                null;  -- unknown opcode, all signals stay at safe defaults

        end case;
    end process;

end architecture behavioral;
