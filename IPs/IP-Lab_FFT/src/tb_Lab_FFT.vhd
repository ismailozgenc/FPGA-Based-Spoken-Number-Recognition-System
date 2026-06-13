library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_Lab_FFT is
end entity;

architecture sim of tb_Lab_FFT is

    signal clock_in  : std_logic := '0';
    signal reset_in  : std_logic := '0';
    signal start_in  : std_logic := '0';
    signal ready_out : std_logic;

    signal addr_out  : std_logic_vector(8 downto 0);
    signal data_in   : std_logic_vector(19 downto 0);

    signal addr_in   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out  : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    type win_array_t is array (0 to 511) of std_logic_vector(19 downto 0);
    signal win_samples : win_array_t := (others => (others => '0'));

begin

    dut: entity work.Lab_FFT
        port map (
            reset_in  => reset_in,
            clock_in  => clock_in,
            addr_out  => addr_out,
            data_in   => data_in,
            addr_in   => addr_in,
            data_out  => data_out,
            start_in  => start_in,
            ready_out => ready_out
        );

    clock_proc: process
    begin
        clock_in <= '0';
        wait for CLK_PERIOD / 2;
        clock_in <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    reset_proc: process
    begin
        reset_in <= '1';
        wait for 200 ns;
        reset_in <= '0';
        wait;
    end process;

    ram_model: process(addr_out, win_samples)
    begin
        data_in <= win_samples(to_integer(unsigned(addr_out)));
    end process;

    load_proc: process
        file fin : text open read_mode is "window_in.txt";
        variable L   : line;
        variable val : integer;
    begin
        for i in 0 to 511 loop
            if endfile(fin) then
                exit;
            end if;
            readline(fin, L);
            read(L, val);
            win_samples(i) <= std_logic_vector(to_signed(val, 20));
        end loop;
        wait;
    end process;

    stim_proc: process
    file fout : text open write_mode is "fft_out.txt";
    variable L   : line;
    variable val : integer;
    begin
        wait for 500 ns;
        wait until rising_edge(clock_in);
        start_in <= '1';
        wait until rising_edge(clock_in);
        start_in <= '0';

        wait until ready_out = '0';
        wait until ready_out = '1';

        for i in 0 to 255 loop
            addr_in <= std_logic_vector(to_unsigned(i, 8));
            wait for 20 ns;
            val := to_integer(signed(data_out));
            write(L, val);
            writeline(fout, L);
        end loop;

        wait for 1 us;
        assert false report "TB finished" severity failure;
    end process;

end architecture;
