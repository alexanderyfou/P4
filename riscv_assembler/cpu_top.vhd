library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;

entity cpu_top is
    port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        debug_wb_data      : out std_logic_vector(31 downto 0);
        debug_wb_rd_addr   : out std_logic_vector(4 downto 0);
        debug_wb_reg_write : out std_logic
    );
end entity cpu_top;

architecture structural of cpu_top is

    -- connecting the frontend, execute stage, memory stage, and writeback stage
    -- into one complete datapath for integration and testing.

    --------------------------------------------------------------------
    -- Frontend -> Execute signals (outputs of frontend / ID-EX outputs)
    --------------------------------------------------------------------
    signal fe_pc           : std_logic_vector(31 downto 0);
    signal fe_rs1_data     : std_logic_vector(31 downto 0);
    signal fe_rs2_data     : std_logic_vector(31 downto 0);
    signal fe_immediate    : std_logic_vector(31 downto 0);
    signal fe_rd_addr      : std_logic_vector(4 downto 0);
    signal fe_rs1_addr     : std_logic_vector(4 downto 0);
    signal fe_rs2_addr     : std_logic_vector(4 downto 0);
    signal fe_funct3       : std_logic_vector(2 downto 0);
    signal fe_funct7       : std_logic_vector(6 downto 0);
    signal fe_opcode       : std_logic_vector(6 downto 0);

    signal fe_alu_op       : std_logic_vector(3 downto 0);
    signal fe_alu_src_a    : std_logic_vector(1 downto 0);
    signal fe_alu_src_b    : std_logic;
    signal fe_branch       : std_logic;
    signal fe_jump         : std_logic;
    signal fe_is_jalr      : std_logic;
    signal fe_mem_read     : std_logic;
    signal fe_mem_write    : std_logic;
    signal fe_reg_write    : std_logic;
    signal fe_mem_to_reg   : std_logic;

    --------------------------------------------------------------------
    -- Execute -> EX/MEM signals
    --------------------------------------------------------------------
    signal ex_alu_result    : std_logic_vector(31 downto 0);
    signal ex_branch_target : std_logic_vector(31 downto 0);
    signal ex_branch_taken  : std_logic;
    signal ex_rs2_data_out  : std_logic_vector(31 downto 0);

    --------------------------------------------------------------------
    -- EX/MEM -> MEM signals
    --------------------------------------------------------------------
    signal exmem_alu_result    : std_logic_vector(31 downto 0);
    signal exmem_branch_target : std_logic_vector(31 downto 0);
    signal exmem_branch_taken  : std_logic;
    signal exmem_rs2_data      : std_logic_vector(31 downto 0);
    signal exmem_rd_addr       : std_logic_vector(4 downto 0);
    signal exmem_funct3        : std_logic_vector(2 downto 0);
    signal exmem_mem_read      : std_logic;
    signal exmem_mem_write     : std_logic;
    signal exmem_reg_write     : std_logic;
    signal exmem_mem_to_reg    : std_logic;

    --------------------------------------------------------------------
    -- MEM -> MEM/WB signals
    --------------------------------------------------------------------
    signal mem_mem_data_out      : std_logic_vector(31 downto 0);
    signal mem_alu_result_out    : std_logic_vector(31 downto 0);
    signal mem_rd_addr_out       : std_logic_vector(4 downto 0);
    signal mem_reg_write_out     : std_logic;
    signal mem_mem_to_reg_out    : std_logic;
    signal mem_branch_target_out : std_logic_vector(31 downto 0);
    signal mem_branch_taken_out  : std_logic;
    signal mem_waitrequest_out   : std_logic;

    --------------------------------------------------------------------
    -- MEM/WB -> WB signals
    --------------------------------------------------------------------
    signal memwb_mem_data     : std_logic_vector(31 downto 0);
    signal memwb_alu_result   : std_logic_vector(31 downto 0);
    signal memwb_rd_addr      : std_logic_vector(4 downto 0);
    signal memwb_reg_write    : std_logic;
    signal memwb_mem_to_reg   : std_logic;

    --------------------------------------------------------------------
    -- WB -> Frontend feedback signals
    --------------------------------------------------------------------
    signal wb_data       : std_logic_vector(31 downto 0);
    signal wb_rd_addr    : std_logic_vector(4 downto 0);
    signal wb_reg_write  : std_logic;

    --------------------------------------------------------------------
    -- HAZARD DETECTION SIGNALS
    --------------------------------------------------------------------
    signal hdu_stall_pc        : std_logic;
    signal hdu_stall_if_id     : std_logic;
    signal hdu_flush_if_id     : std_logic;
    signal hdu_flush_id_ex     : std_logic;
    signal hdu_flush_ex_mem    : std_logic;
    signal pc_enable           : std_logic; -- = inverse of hdu_stall_pc (enable when NOT stalled!)

    signal if_id_instr         : std_logic_vector(31 downto 0);
    signal id_ex_instr         : std_logic_vector(31 downto 0);
    signal ex_mem_instr        : std_logic_vector(31 downto 0);
    signal mem_wb_instr        : std_logic_vector(31 downto 0);


begin

    pc_enable <= not hdu_stall_pc;

    --------------------------------------------------------------------
    -- FRONTEND
    -- For now, hazard controls are tied to safe defaults:
    -- no stalling, no flushing.
    --------------------------------------------------------------------
    frontend_inst : entity work.frontend
        port map (
            clk              => clk,
            reset            => reset,

            pc_enable        => pc_enable,
            ifid_stall       => hdu_stall_if_id,
            ifid_flush       => hdu_flush_if_id,
            id_stall         => hdu_stall_if_id,
            id_flush         => hdu_flush_id_ex,

            branch_taken_in  => mem_branch_taken_out,
            branch_target_in => mem_branch_target_out,

            wb_data          => wb_data,
            wb_rd_addr       => wb_rd_addr,
            wb_reg_write     => wb_reg_write,

            pc_out           => fe_pc,
            rs1_data_out     => fe_rs1_data,
            rs2_data_out     => fe_rs2_data,
            immediate_out    => fe_immediate,
            rd_addr_out      => fe_rd_addr,
            rs1_addr_out     => fe_rs1_addr,
            rs2_addr_out     => fe_rs2_addr,
            funct3_out       => fe_funct3,
            funct7_out       => fe_funct7,
            opcode_out       => fe_opcode,

            alu_op_out       => fe_alu_op,
            alu_src_a_out    => fe_alu_src_a,
            alu_src_b_out    => fe_alu_src_b,
            branch_out       => fe_branch,
            jump_out         => fe_jump,
            is_jalr_out      => fe_is_jalr,
            mem_read_out     => fe_mem_read,
            mem_write_out    => fe_mem_write,
            reg_write_out    => fe_reg_write,
            mem_to_reg_out   => fe_mem_to_reg,

            if_id_instr_output => if_id_instr,
            id_ex_instr_output => id_ex_instr
        );

    --------------------------------------------------------------------
    -- EXECUTE STAGE
    --------------------------------------------------------------------
    execute_inst : entity work.execute_stage
        port map (
            pc            => fe_pc,
            rs1_data      => fe_rs1_data,
            rs2_data      => fe_rs2_data,
            immediate     => fe_immediate,
            funct3        => fe_funct3,

            alu_op        => fe_alu_op,
            alu_src_a     => fe_alu_src_a,
            alu_src_b     => fe_alu_src_b,
            branch        => fe_branch,
            jump          => fe_jump,
            is_jalr       => fe_is_jalr,

            alu_result    => ex_alu_result,
            branch_target => ex_branch_target,
            branch_taken  => ex_branch_taken,
            rs2_data_out  => ex_rs2_data_out
        );

    --------------------------------------------------------------------
    -- EX/MEM PIPELINE REGISTER
    --------------------------------------------------------------------
    exmem_inst : entity work.ex_mem_register
        port map (
            clk              => clk,
            reset            => reset,
            flush            => hdu_flush_ex_mem,
            stall            => '0', 

            alu_result_in    => ex_alu_result,
            branch_target_in => ex_branch_target,
            branch_taken_in  => ex_branch_taken,
            rs2_data_in      => ex_rs2_data_out,
            rd_addr_in       => fe_rd_addr,
            funct3_in        => fe_funct3,
            instr_in         => id_ex_instr,

            mem_read_in      => fe_mem_read,
            mem_write_in     => fe_mem_write,
            reg_write_in     => fe_reg_write,
            mem_to_reg_in    => fe_mem_to_reg,

            alu_result_out    => exmem_alu_result,
            branch_target_out => exmem_branch_target,
            branch_taken_out  => exmem_branch_taken,
            rs2_data_out      => exmem_rs2_data,
            rd_addr_out       => exmem_rd_addr,
            funct3_out        => exmem_funct3,

            mem_read_out      => exmem_mem_read,
            mem_write_out     => exmem_mem_write,
            reg_write_out     => exmem_reg_write,
            mem_to_reg_out    => exmem_mem_to_reg,
            instr_out        => ex_mem_instr
        );

    --------------------------------------------------------------------
    -- MEMORY STAGE
    --------------------------------------------------------------------
    memory_stage_inst : entity work.memory_stage
        port map (
            clk               => clk,

            alu_result        => exmem_alu_result,
            branch_target     => exmem_branch_target,
            branch_taken      => exmem_branch_taken,
            rs2_data          => exmem_rs2_data,
            rd_addr           => exmem_rd_addr,
            funct3            => exmem_funct3,

            mem_read          => exmem_mem_read,
            mem_write         => exmem_mem_write,
            reg_write         => exmem_reg_write,
            mem_to_reg        => exmem_mem_to_reg,

            mem_data_out      => mem_mem_data_out,
            alu_result_out    => mem_alu_result_out,
            rd_addr_out       => mem_rd_addr_out,
            reg_write_out     => mem_reg_write_out,
            mem_to_reg_out    => mem_mem_to_reg_out,

            branch_target_out => mem_branch_target_out,
            branch_taken_out  => mem_branch_taken_out,

            waitrequest_out   => mem_waitrequest_out
        );

    --------------------------------------------------------------------
    -- MEM/WB PIPELINE REGISTER
    --------------------------------------------------------------------
    memwb_inst : entity work.mem_wb_register
        port map (
            clk            => clk,
            reset          => reset,
            flush          => '0',
            stall          => '0',

            mem_data_in    => mem_mem_data_out,
            alu_result_in  => mem_alu_result_out,
            rd_addr_in     => mem_rd_addr_out,

            reg_write_in   => mem_reg_write_out,
            mem_to_reg_in  => mem_mem_to_reg_out,
            instr_in       => ex_mem_instr,

            mem_data_out   => memwb_mem_data,
            alu_result_out => memwb_alu_result,
            rd_addr_out    => memwb_rd_addr,

            reg_write_out  => memwb_reg_write,
            mem_to_reg_out => memwb_mem_to_reg,
            instr_out      => mem_wb_instr
        );

    --------------------------------------------------------------------
    -- WRITEBACK STAGE
    --------------------------------------------------------------------
    writeback_inst : entity work.writeback_stage
        port map (
            mem_data      => memwb_mem_data,
            alu_result    => memwb_alu_result,
            rd_addr       => memwb_rd_addr,
            reg_write     => memwb_reg_write,
            mem_to_reg    => memwb_mem_to_reg,

            wb_data       => wb_data,
            wb_rd_addr    => wb_rd_addr,
            wb_reg_write  => wb_reg_write
        );

    --------------------------------------------------------------------
    -- HAZARD DETECTION UNIT
    --------------------------------------------------------------------
    hazard_detection_unit_inst : entity work.hazard_detection_unit
        port map (
            if_id_inst => if_id_instr,
            id_ex_inst => id_ex_instr,
            ex_mem_inst => ex_mem_instr,
            mem_wb_inst => mem_wb_instr,
            branch_taken => exmem_branch_taken, 

            stall_pc => hdu_stall_pc,
            stall_if_id => hdu_stall_if_id,
            flush_if_id => hdu_flush_if_id,
            flush_id_ex => hdu_flush_id_ex,
            flush_ex_mem => hdu_flush_ex_mem
        );

    debug_wb_data      <= wb_data;
    debug_wb_rd_addr   <= wb_rd_addr;
    debug_wb_reg_write <= wb_reg_write;

    
end architecture structural;