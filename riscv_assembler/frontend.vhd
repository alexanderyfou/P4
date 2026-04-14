library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;

entity frontend is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;

        -- hazard / pipeline control
        pc_enable        : in  std_logic;
        ifid_stall       : in  std_logic;

        ifid_flush       : in  std_logic;
        id_stall         : in  std_logic;

        id_flush         : in  std_logic;

        -- branch/jump redirect
        branch_taken_in  : in  std_logic;
        branch_target_in : in  std_logic_vector(31 downto 0);

        -- writeback inputs from WB
        wb_data          : in  std_logic_vector(31 downto 0);
        wb_rd_addr       : in  std_logic_vector(4 downto 0);
        wb_reg_write     : in  std_logic;

        -- outputs to execute stage
        pc_out           : out std_logic_vector(31 downto 0);
        rs1_data_out     : out std_logic_vector(31 downto 0);

        rs2_data_out     : out std_logic_vector(31 downto 0);
        immediate_out    : out std_logic_vector(31 downto 0);
        rd_addr_out      : out std_logic_vector(4 downto 0);

        rs1_addr_out     : out std_logic_vector(4 downto 0);
        rs2_addr_out     : out std_logic_vector(4 downto 0);

        funct3_out       : out std_logic_vector(2 downto 0);
        funct7_out       : out std_logic_vector(6 downto 0);

        opcode_out       : out std_logic_vector(6 downto 0);

        alu_op_out       : out std_logic_vector(3 downto 0);
        alu_src_a_out    : out std_logic_vector(1 downto 0);
        alu_src_b_out    : out std_logic;

        branch_out       : out std_logic;
        jump_out         : out std_logic;
        is_jalr_out      : out std_logic;

        mem_read_out     : out std_logic;
        mem_write_out    : out std_logic;
        reg_write_out    : out std_logic;

        mem_to_reg_out   : out std_logic;

        if_id_instr_output : out std_logic_vector(31 downto 0);  -- for hazard detection
        id_ex_instr_output : out std_logic_vector(31 downto 0)  -- for hazard detection
    );
end entity frontend;



architecture behavioral of frontend is

    -- connecting the fetch and decode parts of the processor.
    -- combines PC, instruction memory, IF/ID reg, and decode stage,
    -- and handles writeback inputs and branc PC redirection.

    signal pc_current    : std_logic_vector(31 downto 0);
    signal pc_plus_4     : std_logic_vector(31 downto 0);
    signal pc_next       : std_logic_vector(31 downto 0);

    signal instr_fetched : std_logic_vector(31 downto 0);

    signal ifid_pc       : std_logic_vector(31 downto 0);
    signal ifid_instr    : std_logic_vector(31 downto 0);
    signal idex_instr    : std_logic_vector(31 downto 0);



begin

    -- normal sequential
    pc_plus_4 <= std_logic_vector(unsigned(pc_current) + 4);

    -- redirect PC if branch/jump is taken
    pc_next <= branch_target_in when branch_taken_in = '1' else pc_plus_4;

    if_id_instr_output <= ifid_instr;
    id_ex_instr_output <= idex_instr;

    -- PC register
    pc_reg_inst : entity work.pc_register
        port map (
            clk     => clk,
            reset   => reset,
            enable  => pc_enable,
            next_pc => pc_next,
            pc_out  => pc_current
        );

    -- instruction memory
    imem_inst : entity work.instruction_memory
        port map (
            address     => pc_current,
            instruction => instr_fetched
        );

    -- IF/ID pipeline register
    ifid_inst : entity work.if_id_register
        port map (
            clk       => clk,
            reset     => reset,
            stall     => ifid_stall,
            flush     => ifid_flush,

            pc_in     => pc_current,
            instr_in  => instr_fetched,

            pc_out    => ifid_pc,
            instr_out => ifid_instr
        );

    -- decode stage
    decode_inst : entity work.decode_stage
        port map (
            clk             => clk,
            reset           => reset,
            stall           => id_stall,
            flush           => id_flush,

            pc_in           => ifid_pc,
            instr_in        => ifid_instr,

            wb_reg_write    => wb_reg_write,
            wb_rd_addr      => wb_rd_addr,
            wb_write_data   => wb_data,

            pc_out          => pc_out,
            rs1_data_out    => rs1_data_out,
            rs2_data_out    => rs2_data_out,
            immediate_out   => immediate_out,

            rd_addr_out     => rd_addr_out,
            rs1_addr_out    => rs1_addr_out,
            rs2_addr_out    => rs2_addr_out,

            funct3_out      => funct3_out,
            funct7_out      => funct7_out,



            opcode_out      => opcode_out,

            alu_op_out      => alu_op_out,
            alu_src_a_out   => alu_src_a_out,
            alu_src_b_out   => alu_src_b_out,
            branch_out      => branch_out,
            jump_out        => jump_out,

            
            is_jalr_out     => is_jalr_out,
            mem_read_out    => mem_read_out,
            mem_write_out   => mem_write_out,
            reg_write_out   => reg_write_out,
            mem_to_reg_out  => mem_to_reg_out,

            instr_out      => idex_instr
        );

end architecture behavioral;