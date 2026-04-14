-- id_ex_register.vhd
-- Pipeline register between Decode (ID) and Execute (EX) stages.
--
-- Captures data values and control signals on each rising clock edge.
-- Has flush and stall inputs for hazard handling (Person 4):
--   flush: inserts a bubble by zeroing all control signals
--   stall: holds current values (freezes the register)
-- Priority: reset > flush > stall > normal update

library ieee;
use ieee.std_logic_1164.all;

entity id_ex_register is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        flush : in std_logic;  -- insert bubble (from hazard unit)
        stall : in std_logic;  -- hold values (from hazard unit)

        -- data inputs (from ID stage / Person 1)
        pc_in        : in std_logic_vector(31 downto 0);
        rs1_data_in  : in std_logic_vector(31 downto 0);
        rs2_data_in  : in std_logic_vector(31 downto 0);
        immediate_in : in std_logic_vector(31 downto 0);
        rd_addr_in   : in std_logic_vector(4 downto 0);   -- instr[11:7]
        rs1_addr_in  : in std_logic_vector(4 downto 0);   -- instr[19:15]
        rs2_addr_in  : in std_logic_vector(4 downto 0);   -- instr[24:20]
        funct3_in    : in std_logic_vector(2 downto 0);   -- instr[14:12]
        funct7_in    : in std_logic_vector(6 downto 0);   -- instr[31:25]
        opcode_in    : in std_logic_vector(6 downto 0);   -- instr[6:0]
        instr_in     : in std_logic_vector(31 downto 0);  -- full instruction for hazard detection

        -- control inputs (from control_unit)
        alu_op_in     : in std_logic_vector(3 downto 0);
        alu_src_a_in  : in std_logic_vector(1 downto 0);
        alu_src_b_in  : in std_logic;
        branch_in     : in std_logic;
        jump_in       : in std_logic;
        is_jalr_in    : in std_logic;
        mem_read_in   : in std_logic;
        mem_write_in  : in std_logic;
        reg_write_in  : in std_logic;
        mem_to_reg_in : in std_logic;

        -- data outputs (to EX stage)
        pc_out        : out std_logic_vector(31 downto 0);
        rs1_data_out  : out std_logic_vector(31 downto 0);
        rs2_data_out  : out std_logic_vector(31 downto 0);
        immediate_out : out std_logic_vector(31 downto 0);
        rd_addr_out   : out std_logic_vector(4 downto 0);
        rs1_addr_out  : out std_logic_vector(4 downto 0);
        rs2_addr_out  : out std_logic_vector(4 downto 0);
        funct3_out    : out std_logic_vector(2 downto 0);
        funct7_out    : out std_logic_vector(6 downto 0);
        opcode_out    : out std_logic_vector(6 downto 0);

        -- control outputs (to EX stage and forwarded downstream)
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
        instr_out      : out std_logic_vector(31 downto 0)  -- full instruction for hazard detection
    );
end entity id_ex_register;

architecture behavioral of id_ex_register is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- clear everything
                pc_out        <= (others => '0');
                rs1_data_out  <= (others => '0');
                rs2_data_out  <= (others => '0');
                immediate_out <= (others => '0');
                rd_addr_out   <= (others => '0');
                rs1_addr_out  <= (others => '0');
                rs2_addr_out  <= (others => '0');
                funct3_out    <= (others => '0');
                funct7_out    <= (others => '0');
                opcode_out    <= (others => '0');
                alu_op_out     <= (others => '0');
                alu_src_a_out  <= (others => '0');
                alu_src_b_out  <= '0';
                branch_out     <= '0';
                jump_out       <= '0';
                is_jalr_out    <= '0';
                mem_read_out   <= '0';
                mem_write_out  <= '0';
                reg_write_out  <= '0';
                mem_to_reg_out <= '0';
                instr_out      <= (others => '0');

            elsif flush = '1' then
                -- insert bubble: zero everything so nothing writes or reads
                pc_out        <= (others => '0');
                rs1_data_out  <= (others => '0');
                rs2_data_out  <= (others => '0');
                immediate_out <= (others => '0');
                rd_addr_out   <= (others => '0');
                rs1_addr_out  <= (others => '0');
                rs2_addr_out  <= (others => '0');
                funct3_out    <= (others => '0');
                funct7_out    <= (others => '0');
                opcode_out    <= (others => '0');
                alu_op_out     <= (others => '0');
                alu_src_a_out  <= (others => '0');
                alu_src_b_out  <= '0';
                branch_out     <= '0';
                jump_out       <= '0';
                is_jalr_out    <= '0';
                mem_read_out   <= '0';
                mem_write_out  <= '0';
                reg_write_out  <= '0';
                mem_to_reg_out <= '0';
                instr_out      <= (others => '0');

            elsif stall = '0' then
                -- normal: capture inputs
                pc_out        <= pc_in;
                rs1_data_out  <= rs1_data_in;
                rs2_data_out  <= rs2_data_in;
                immediate_out <= immediate_in;
                rd_addr_out   <= rd_addr_in;
                rs1_addr_out  <= rs1_addr_in;
                rs2_addr_out  <= rs2_addr_in;
                funct3_out    <= funct3_in;
                funct7_out    <= funct7_in;
                opcode_out    <= opcode_in;
                alu_op_out     <= alu_op_in;
                alu_src_a_out  <= alu_src_a_in;
                alu_src_b_out  <= alu_src_b_in;
                branch_out     <= branch_in;
                jump_out       <= jump_in;
                is_jalr_out    <= is_jalr_in;
                mem_read_out   <= mem_read_in;
                mem_write_out  <= mem_write_in;
                reg_write_out  <= reg_write_in;
                mem_to_reg_out <= mem_to_reg_in;
                instr_out <= instr_in;  -- for hazard detection
            end if;
            -- stall=1 and flush=0: do nothing, hold current values
        end if;
    end process;

end architecture behavioral;