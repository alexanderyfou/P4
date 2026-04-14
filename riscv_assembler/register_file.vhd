library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        read_addr1   : in  std_logic_vector(4 downto 0);
        read_addr2   : in  std_logic_vector(4 downto 0);
        read_data1   : out std_logic_vector(31 downto 0);
        read_data2   : out std_logic_vector(31 downto 0);
        write_enable : in  std_logic;
        write_addr   : in  std_logic_vector(4 downto 0);
        write_data   : in  std_logic_vector(31 downto 0)
    );
end entity register_file;

architecture behavioral of register_file is

    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_array := (others => (others => '0'));

begin

    -- providing two read ports and one write port, and keeps x0 permanently
    -- tied to zero.

    read_data1 <= (others => '0') when read_addr1 = "00000" else regs(to_integer(unsigned(read_addr1)));
    read_data2 <= (others => '0') when read_addr2 = "00000" else regs(to_integer(unsigned(read_addr2)));

    process(clk)

    begin

        if rising_edge(clk) then

            if reset = '1' then
                regs <= (others => (others => '0'));

            else

                if write_enable = '1' and write_addr /= "00000" then

                    regs(to_integer(unsigned(write_addr))) <= write_data;

                end if;

                regs(0) <= (others => '0');

            end if;

        end if;
        
    end process;
end architecture behavioral;