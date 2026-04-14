library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

entity mem_wb_register is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        flush : in std_logic;  -- from hazard / control logic later
        stall : in std_logic;  -- from hazard / control logic later

        -- data inputs (from MEM stage)
        mem_data_in    : in std_logic_vector(31 downto 0);
        alu_result_in  : in std_logic_vector(31 downto 0);
        rd_addr_in     : in std_logic_vector(4 downto 0);

        -- control inputs
        reg_write_in   : in std_logic;
        mem_to_reg_in  : in std_logic;
        instr_in         : in std_logic_vector(31 downto 0);  -- full instruction for hazard detection

        -- data outputs (to WB stage)
        mem_data_out   : out std_logic_vector(31 downto 0);
        alu_result_out : out std_logic_vector(31 downto 0);
        rd_addr_out    : out std_logic_vector(4 downto 0);

        -- control outputs
        reg_write_out  : out std_logic;
        mem_to_reg_out : out std_logic;
        instr_out         : out std_logic_vector(31 downto 0)  -- full instruction for hazard detection
    );
end entity mem_wb_register;

architecture behavioral of mem_wb_register is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- clear everything
                mem_data_out    <= (others => '0');
                alu_result_out  <= (others => '0');
                rd_addr_out     <= (others => '0');

                reg_write_out   <= '0';
                mem_to_reg_out  <= '0';
                instr_out <= (others => '0');

            elsif flush = '1' then
                -- insert bubble
                mem_data_out    <= (others => '0');
                alu_result_out  <= (others => '0');
                rd_addr_out     <= (others => '0');

                reg_write_out   <= '0';
                mem_to_reg_out  <= '0';
                instr_out <= (others => '0');

            elsif stall = '0' then
                -- normal update
                mem_data_out    <= mem_data_in;
                alu_result_out  <= alu_result_in;
                rd_addr_out     <= rd_addr_in;

                reg_write_out   <= reg_write_in;
                mem_to_reg_out  <= mem_to_reg_in;
                instr_out      <= instr_in;
            end if;
            -- stall = 1 and flush = 0: hold current values
        end if;
    end process;

end architecture behavioral;