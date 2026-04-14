-- Author: Alexander Fou
-- Date: April 7 2026
-- Hazard detection unit for detecting stalls

-- Comments for myself down below vvv
-- detects stalls in ID when an operand isn't ready, eg after a load or an ALU op
-- insert a stall into the pipeline with the following: 0+0 -> r0 ("addi $x0, $x0, 0")
-- insert it into the ex stage

-- for data hazards stall IF/ID + PC and flush ID/EX, and for branches flush IF/ID, ID/EX, and EX/MEM
-- data hazard: read a reg but must wait for it to be written to
-- control hazard: branch or jump

-- Register type: add, sub, mul, or, and, sll, srl, sra
-- Immediate: addi, xori, ori, andi, slti, lw
-- Store: sw
-- Branch: beq, bne, blt, bge
-- Misc: jal, jalr, lui, auipc

-- write insts: all register + immediate type + lw, jal, jalr, lui, auipc
-- reads: all register + immediate + lw, sw, branch types, jalr

library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

entity hazard_detection_unit is
    port (
        if_id_inst : in std_logic_vector(31 downto 0); -- instruction in IF/ID
        id_ex_inst : in std_logic_vector(31 downto 0); -- instruction in ID/EX
        ex_mem_inst : in std_logic_vector(31 downto 0); -- instruction in EX/MEM
        mem_wb_inst : in std_logic_vector(31 downto 0); -- instruction in MEM/WB
        branch_taken : in std_logic;  -- from branch comparator in EX stage

        stall_pc : out std_logic;
        stall_if_id : out std_logic;
        flush_if_id : out std_logic;
        flush_id_ex : out std_logic;
        flush_ex_mem : out std_logic
    );
end entity hazard_detection_unit;

-- given an inst, do either of the source registers match the destination of the instruction in the execute or memory stage?
-- if so then stall
architecture rtl of hazard_detection_unit is

    -- function to check if an instruction writes to a register
    function get_reg_write(inst : std_logic_vector(31 downto 0)) return boolean is
        variable opcode : std_logic_vector(6 downto 0);
    begin
        opcode := inst(6 downto 0);
        if opcode = OP_R_TYPE or opcode = OP_I_ARITH or opcode = OP_LOAD or opcode = OP_JAL or opcode = OP_JALR or opcode = OP_LUI or opcode = OP_AUIPC then
            return true;
        else
            return false;
        end if;
    end function get_reg_write;

begin
    process(if_id_inst, id_ex_inst, ex_mem_inst, mem_wb_inst, branch_taken)
        variable opcode : std_logic_vector(6 downto 0);

        variable rs1 : std_logic_vector(4 downto 0);
        variable rs2 : std_logic_vector(4 downto 0);

        -- will we be reading from these registers? yes or no
        variable reads_rs1 : boolean;
        variable reads_rs2 : boolean;

        variable rd_ex : std_logic_vector(4 downto 0);
        variable rd_mem : std_logic_vector(4 downto 0);
        variable rd_wb : std_logic_vector(4 downto 0);

        -- are we writing to registers?
        variable id_ex_reg_write : boolean;
        variable ex_mem_reg_write : boolean;
        variable mem_wb_reg_write : boolean;

        variable data_hazard : boolean;
    begin
        -- default: no stalls or flushes
        stall_pc <= '0';
        stall_if_id <= '0';
        flush_if_id <= '0';
        flush_id_ex <= '0';
        flush_ex_mem <= '0';

        -- extract fields
        opcode := if_id_inst(6 downto 0);
        rs1 := if_id_inst(19 downto 15);
        rs2 := if_id_inst(24 downto 20);

        rd_ex := id_ex_inst(11 downto 7);
        rd_mem := ex_mem_inst(11 downto 7);
        rd_wb := mem_wb_inst(11 downto 7);

        id_ex_reg_write := get_reg_write(id_ex_inst);
        ex_mem_reg_write := get_reg_write(ex_mem_inst);
        mem_wb_reg_write := get_reg_write(mem_wb_inst);

        -- are we reading register source 1?
        if opcode = OP_R_TYPE or opcode = OP_I_ARITH or opcode = OP_LOAD or opcode = OP_STORE or opcode = OP_BRANCH or opcode = OP_JALR then
            reads_rs1 := true;
        else
            reads_rs1 := false;
        end if;

        -- are we reading register source 2?
        if opcode = OP_R_TYPE or opcode = OP_STORE or opcode = OP_BRANCH then
            reads_rs2 := true;
        else
            reads_rs2 := false;
        end if;

        -- data hazard if:
        -- if we read a register in the ID stage AND
        -- that register is the destination of an instruction in EX, MEM, or WB that hasn't written yet
        -- AND it's not the zero register (cause r/w to zero register doesn't matter)
        data_hazard := (
            (id_ex_reg_write = true and rd_ex /= "00000" and ((reads_rs1 = true and rs1 = rd_ex) or (reads_rs2 = true and rs2 = rd_ex))) or
            (ex_mem_reg_write = true and rd_mem /= "00000" and ((reads_rs1 = true and rs1 = rd_mem) or (reads_rs2 = true and rs2 = rd_mem))) or
            (mem_wb_reg_write = true and rd_wb  /= "00000" and ((reads_rs1 = true and rs1 = rd_wb) or (reads_rs2 = true and rs2 = rd_wb)))
        );
        
        -- for branches, we flush if/id, id/ex, ex/mem
        if branch_taken = '1' then
            flush_if_id <= '1';
            flush_id_ex <= '1';
            flush_ex_mem <= '1';
        elsif data_hazard then
            -- stall PC, IF/ID, and flush ID/EX. We use an elsif to give the taken branch priority over stalling.
            stall_pc <= '1';
            stall_if_id <= '1';
            flush_id_ex <= '1';
        end if;
    end process;
end architecture rtl;