library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;

entity memory_stage is
    port (
        clk : in std_logic;

        -- inputs from EX/MEM register
        alu_result    : in std_logic_vector(31 downto 0); 
        branch_target : in std_logic_vector(31 downto 0); 
        branch_taken  : in std_logic;                     
        rs2_data      : in std_logic_vector(31 downto 0); 
        rd_addr       : in std_logic_vector(4 downto 0);
        funct3        : in std_logic_vector(2 downto 0);  

        -- control inputs from EX/MEM register
        mem_read      : in std_logic;
        mem_write     : in std_logic;
        reg_write     : in std_logic;
        mem_to_reg    : in std_logic;

        -- outputs to MEM/WB register
        mem_data_out   : out std_logic_vector(31 downto 0);
        alu_result_out : out std_logic_vector(31 downto 0);
        rd_addr_out    : out std_logic_vector(4 downto 0);
        reg_write_out  : out std_logic;
        mem_to_reg_out : out std_logic;

        -- forwarded branch info (for integration / control logic later)
        branch_target_out : out std_logic_vector(31 downto 0);
        branch_taken_out  : out std_logic;

        -- memory status
        waitrequest_out : out std_logic
    );
end entity memory_stage;

architecture structural of memory_stage is
    signal mem_address_int : integer range 0 to 32767;
    signal mem_readdata    : std_logic_vector(31 downto 0);
    signal mem_waitrequest : std_logic;
begin

    -- Need the addr in int
    mem_address_int <= to_integer(unsigned(alu_result(14 downto 0))) 
                    when (mem_read = '1' or mem_write = '1') 
                    else 0;
    -- Data memory instance
    data_mem_inst : entity work.memory
        port map (
            clock       => clk,
            writedata   => rs2_data,
            address     => mem_address_int,
            memwrite    => mem_write,
            memread     => mem_read,
            readdata    => mem_readdata,
            waitrequest => mem_waitrequest
        );

    -- For lw/sw only:
    mem_data_out <= mem_readdata when mem_read = '1' else (others => '0');

    -- Forward everything needed to the writeback stage
    alu_result_out <= alu_result;
    rd_addr_out    <= rd_addr;
    reg_write_out  <= reg_write;
    mem_to_reg_out <= mem_to_reg;

    -- Branch logic should be checked : if branch_taken_out and then go to branch_target_out
    branch_target_out <= branch_target;
    branch_taken_out  <= branch_taken;

    -- Forward memory waitrequest we need to use it
    waitrequest_out <= mem_waitrequest;

end architecture structural;