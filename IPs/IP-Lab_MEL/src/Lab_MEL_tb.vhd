library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab_MEL_tb is
end entity;

architecture sim of Lab_MEL_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clock_in     : std_logic := '0';
    signal reset_in     : std_logic := '0';
    signal start_in     : std_logic := '0';

    signal fft_addr_out : std_logic_vector(7 downto 0);
    signal fft_data_in  : std_logic_vector(31 downto 0) := (others => '0');

    signal mem_addr_in  : std_logic_vector(4 downto 0) := (others => '0');
    signal mem_data_out : std_logic_vector(31 downto 0);

    signal ready_out    : std_logic;

    constant FFT_CONST : std_logic_vector(31 downto 0) := x"00010000";

    type mel_vec_t is array (0 to 31) of std_logic_vector(31 downto 0);
    constant expected_vals : mel_vec_t := (
        0  => (others => '0'),
        1  => (others => '0'),
        2  => (others => '0'),
        3  => (others => '0'),
        4  => (others => '0'),
        5  => (others => '0'),
        6  => (others => '0'),
        7  => (others => '0'),
        8  => (others => '0'),
        9  => (others => '0'),
        10 => (others => '0'),
        11 => (others => '0'),
        12 => (others => '0'),
        13 => (others => '0'),
        14 => (others => '0'),
        15 => (others => '0'),
        16 => (others => '0'),
        17 => (others => '0'),
        18 => (others => '0'),
        19 => (others => '0'),
        20 => (others => '0'),
        21 => (others => '0'),
        22 => (others => '0'),
        23 => (others => '0'),
        24 => (others => '0'),
        25 => (others => '0'),
        26 => (others => '0'),
        27 => (others => '0'),
        28 => (others => '0'),
        29 => (others => '0'),
        30 => (others => '0'),
        31 => (others => '0')
    );

begin

    uut: entity work.Lab_MEL
        port map (
            reset_in     => reset_in,
            clock_in     => clock_in,
            fft_addr_out => fft_addr_out,
            fft_data_in  => fft_data_in,
            mem_addr_in  => mem_addr_in,
            mem_data_out => mem_data_out,
            start_in     => start_in,
            ready_out    => ready_out
        );

    clk_gen : process
    begin
        while true loop
            clock_in <= '0';
            wait for CLK_PERIOD/2;
            clock_in <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    stim_proc : process
        variable i : integer := 0;
    begin
        reset_in <= '1';
        wait for 5*CLK_PERIOD;
        reset_in <= '0';
        wait for 5*CLK_PERIOD;

        fft_data_in <= FFT_CONST;

        start_in <= '1';
        wait for CLK_PERIOD;
        start_in <= '0';

        wait until ready_out = '1';

        for i in 0 to 31 loop
            mem_addr_in <= std_logic_vector(to_unsigned(i, mem_addr_in'length));
            wait for CLK_PERIOD;
        end loop;
        
        wait for 10*CLK_PERIOD;
        report "Simulation finished" severity note;
        wait;
    end process;

end architecture;
