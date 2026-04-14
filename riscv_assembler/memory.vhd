library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
	generic(
		ram_size : integer := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	port (
		clock: in std_logic;
		writedata: in std_logic_vector (31 downto 0);
		address: in integer range 0 to ram_size-1;
		memwrite: in std_logic;
		memread: in std_logic;
		readdata: out std_logic_vector (31 downto 0);
		waitrequest: out std_logic
	);
end memory;

architecture rtl of memory is
	type MEM is array(ram_size-1 downto 0) of std_logic_vector(7 downto 0);
	signal ram_block: MEM;
	signal write_waitreq_reg: std_logic := '1';
	signal read_waitreq_reg: std_logic := '1';
begin
	-- Main SRAM model
	mem_process: process (clock)
	begin
		-- Initialize SRAM in simulation
		if (now < 1 ps) then
			for i in 0 to ram_size-1 loop
				ram_block(i) <= (others => '0');
			end loop;
		end if;

		-- Synchronous write
		if rising_edge(clock) then
			if (memwrite = '1') then
				ram_block(address)   <= writedata(7 downto 0);
				ram_block(address+1) <= writedata(15 downto 8);
				ram_block(address+2) <= writedata(23 downto 16);
				ram_block(address+3) <= writedata(31 downto 24);
			end if;
		end if;
	end process;

	-- Combinational read
	readdata <= ram_block(address+3) &
	            ram_block(address+2) &
	            ram_block(address+1) &
	            ram_block(address);

	-- waitrequest signal to vary response time in simulation
	-- Read and write should never happen at the same time.
	waitreq_w_proc: process (memwrite)
	begin
		if (memwrite'event and memwrite = '1') then
			write_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		end if;
	end process;

	waitreq_r_proc: process (memread)
	begin
		if (memread'event and memread = '1') then
			read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		end if;
	end process;

	waitrequest <= write_waitreq_reg and read_waitreq_reg;

end rtl;