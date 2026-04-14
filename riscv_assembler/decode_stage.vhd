library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;

entity decode_stage is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        stall : in  std_logic;
        flush : in  std_logic;

        -- IF/ID
        pc_in    : in  std_logic_vector(31 downto 0);
        instr_in : in  std_logic_vector(31 downto 0);

        -- writeback
        wb_reg_write : in  std_logic;
        wb_rd_addr   : in  std_logic_vector(4 downto 0);
        wb_write_data: in  std_logic_vector(31 downto 0);

        -- ID/EX
        pc_out         : out std_logic_vector(31 downto 0);
        rs1_data_out   : out std_logic_vector(31 downto 0);
        rs2_data_out   : out std_logic_vector(31 downto 0);
        immediate_out  : out std_logic_vector(31 downto 0);
        rd_addr_out    : out std_logic_vector(4 downto 0);
        rs1_addr_out   : out std_logic_vector(4 downto 0);
        rs2_addr_out   : out std_logic_vector(4 downto 0);


        funct3_out     : out std_logic_vector(2 downto 0);
        funct7_out     : out std_logic_vector(6 downto 0);
        opcode_out     : out std_logic_vector(6 downto 0);

        alu_op_out     : out std_logic_vector(3 downto 0);
        alu_src_a_out  : out std_logic_vector(1 downto 0);
        alu_src_b_out  : out std_logic;
        branch_out     : out std_logic;
        jump_out       : out std_logic;
        is_jalr_out    : out std_logic;
        mem_read_out   : out std_logic;
        mem_write_out  : out std_logic;
        reg_write_out  : out std_logic;
        mem_to_reg_out : out std_logic;

        instr_out        : out std_logic_vector(31 downto 0)  -- for hazard detection
    );
end entity decode_stage;

architecture behavioral of decode_stage is

    -- extracts fields, reads the register file, generates the
    -- immediate, calls the control unit, and passes everything to the ID/EX
    -- pipeline register.

    signal opcode     : std_logic_vector(6 downto 0);
    signal rd         : std_logic_vector(4 downto 0);
    signal funct3     : std_logic_vector(2 downto 0);
    signal rs1        : std_logic_vector(4 downto 0);
    signal rs2        : std_logic_vector(4 downto 0);
    signal funct7     : std_logic_vector(6 downto 0);

    signal rs1_data   : std_logic_vector(31 downto 0);
    signal rs2_data   : std_logic_vector(31 downto 0);
    signal immediate  : std_logic_vector(31 downto 0);

    signal alu_op     : std_logic_vector(3 downto 0);
    signal alu_src_a  : std_logic_vector(1 downto 0);
    signal alu_src_b  : std_logic;
    signal branch     : std_logic;
    
    signal jump       : std_logic;
    signal is_jalr    : std_logic;
    signal mem_read   : std_logic;
    signal mem_write  : std_logic;
    signal reg_write  : std_logic;
    signal mem_to_reg : std_logic;

begin

    -- split fields
    opcode <= instr_in(6 downto 0);
    rd     <= instr_in(11 downto 7);

    funct3 <= instr_in(14 downto 12);
    rs1    <= instr_in(19 downto 15);
    rs2    <= instr_in(24 downto 20);

    funct7 <= instr_in(31 downto 25);

    -- register file
    rf_inst : entity work.register_file
        port map (
            clk          => clk,
            reset        => reset,
            read_addr1   => rs1,
            read_addr2   => rs2,
            read_data1   => rs1_data,
            read_data2   => rs2_data,

            write_enable => wb_reg_write,
            write_addr   => wb_rd_addr,
            write_data   => wb_write_data
        );

    -- imm generator
    imm_inst : entity work.immediate_generator
        port map (
            instruction => instr_in,
            immediate   => immediate
        );

    -- control unit
    cu_inst : entity work.control_unit
        port map (
            opcode     => opcode,
            funct3     => funct3,
            funct7     => funct7,

            alu_op     => alu_op,
            alu_src_a  => alu_src_a,
            alu_src_b  => alu_src_b,
            branch     => branch,
            jump       => jump,

            is_jalr    => is_jalr,
            mem_read   => mem_read,
            mem_write  => mem_write,
            reg_write  => reg_write,
            mem_to_reg => mem_to_reg
        );

    -- ID/EX registers
    idex_inst : entity work.id_ex_register
        port map (
            clk           => clk,
            reset         => reset,
            stall         => stall,
            flush         => flush,

            pc_in         => pc_in,
            rs1_data_in   => rs1_data,
            rs2_data_in   => rs2_data,
            immediate_in  => immediate,
            rd_addr_in    => rd,
            rs1_addr_in   => rs1,
            rs2_addr_in   => rs2,
            funct3_in     => funct3,
            funct7_in     => funct7,
            opcode_in     => opcode,
            instr_in      => instr_in,  -- for hazard detection

            alu_op_in     => alu_op,
            alu_src_a_in  => alu_src_a,
            alu_src_b_in  => alu_src_b,
            branch_in     => branch,
            jump_in       => jump,
            is_jalr_in    => is_jalr,
            mem_read_in   => mem_read,
            mem_write_in  => mem_write,
            reg_write_in  => reg_write,
            mem_to_reg_in => mem_to_reg,

            pc_out         => pc_out,
            rs1_data_out   => rs1_data_out,
            rs2_data_out   => rs2_data_out,
            immediate_out  => immediate_out,
            rd_addr_out    => rd_addr_out,
            rs1_addr_out   => rs1_addr_out,
            rs2_addr_out   => rs2_addr_out,
            funct3_out     => funct3_out,
            funct7_out     => funct7_out,
            opcode_out     => opcode_out,

            alu_op_out     => alu_op_out,
            alu_src_a_out  => alu_src_a_out,
            alu_src_b_out  => alu_src_b_out,
            branch_out     => branch_out,
            jump_out       => jump_out,
            is_jalr_out    => is_jalr_out,
            mem_read_out   => mem_read_out,
            mem_write_out  => mem_write_out,
            reg_write_out  => reg_write_out,
            mem_to_reg_out => mem_to_reg_out,
            instr_out     => instr_out
        );

end architecture behavioral;