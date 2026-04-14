library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

entity ex_mem_register is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        flush : in std_logic;  -- from hazard / control logic later
        stall : in std_logic;  -- from hazard / control logic later

        -- data inputs (from EX stage)
        alu_result_in   : in std_logic_vector(31 downto 0);
        branch_target_in: in std_logic_vector(31 downto 0);
        branch_taken_in : in std_logic;
        rs2_data_in     : in std_logic_vector(31 downto 0);
        rd_addr_in      : in std_logic_vector(4 downto 0);
        funct3_in       : in std_logic_vector(2 downto 0);
        instr_in         : in std_logic_vector(31 downto 0);  -- full instruction for hazard detection

        -- control inputs
        mem_read_in     : in std_logic;
        mem_write_in    : in std_logic;
        reg_write_in    : in std_logic;
        mem_to_reg_in   : in std_logic;

        -- data outputs (to MEM stage)
        alu_result_out   : out std_logic_vector(31 downto 0);
        branch_target_out: out std_logic_vector(31 downto 0);
        branch_taken_out : out std_logic;
        rs2_data_out     : out std_logic_vector(31 downto 0);
        rd_addr_out      : out std_logic_vector(4 downto 0);
        funct3_out       : out std_logic_vector(2 downto 0);

        -- control outputs
        mem_read_out     : out std_logic;
        mem_write_out    : out std_logic;
        reg_write_out    : out std_logic;
        mem_to_reg_out   : out std_logic;
        instr_out         : out std_logic_vector(31 downto 0)  -- full instruction for hazard detection
    );
end entity ex_mem_register;

architecture behavioral of ex_mem_register is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- clear everything
                alu_result_out    <= (others => '0');
                branch_target_out <= (others => '0');
                branch_taken_out  <= '0';
                rs2_data_out      <= (others => '0');
                rd_addr_out       <= (others => '0');
                funct3_out        <= (others => '0');

                mem_read_out      <= '0';
                mem_write_out     <= '0';
                reg_write_out     <= '0';
                mem_to_reg_out    <= '0';
                instr_out         <= (others => '0');

            elsif flush = '1' then
                -- insert bubble
                alu_result_out    <= (others => '0');
                branch_target_out <= (others => '0');
                branch_taken_out  <= '0';
                rs2_data_out      <= (others => '0');
                rd_addr_out       <= (others => '0');
                funct3_out        <= (others => '0');

                mem_read_out      <= '0';
                mem_write_out     <= '0';
                reg_write_out     <= '0';
                mem_to_reg_out    <= '0';
                instr_out <= (others => '0');

            elsif stall = '0' then
                -- normal update
                alu_result_out    <= alu_result_in;
                branch_target_out <= branch_target_in;
                branch_taken_out  <= branch_taken_in;
                rs2_data_out      <= rs2_data_in;
                rd_addr_out       <= rd_addr_in;
                funct3_out        <= funct3_in;

                mem_read_out      <= mem_read_in;
                mem_write_out     <= mem_write_in;
                reg_write_out     <= reg_write_in;
                mem_to_reg_out    <= mem_to_reg_in;
                instr_out <= instr_in;
            end if;
            -- stall = 1 and flush = 0: hold current values
        end if;
    end process;

end architecture behavioral;