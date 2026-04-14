library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

entity writeback_stage is
    port (
        -- inputs from MEM/WB register
        mem_data    : in std_logic_vector(31 downto 0);
        alu_result  : in std_logic_vector(31 downto 0);
        rd_addr     : in std_logic_vector(4 downto 0);
        reg_write   : in std_logic;
        mem_to_reg  : in std_logic;

        -- outputs to register file
        wb_data      : out std_logic_vector(31 downto 0);
        wb_rd_addr   : out std_logic_vector(4 downto 0);
        wb_reg_write : out std_logic
    );
end entity writeback_stage;

architecture behavioral of writeback_stage is
begin

    -- writeback mux:
    -- if load write memory data, other cases write ALU
    wb_data <= mem_data when mem_to_reg = '1' else alu_result;

    -- Destination register number
    wb_rd_addr <= rd_addr;
    -- Register file write enable
    wb_reg_write <= reg_write;

    --need to connect those variables to the decode stage

end architecture behavioral;