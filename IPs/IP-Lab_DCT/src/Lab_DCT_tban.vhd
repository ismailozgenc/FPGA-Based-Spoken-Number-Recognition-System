library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab_DCT_tban is
end entity;

architecture sim of Lab_DCT_tban is

    constant CLK_PERIOD : time := 10 ns;

    signal clock_in     : std_logic := '0';
    signal reset_in     : std_logic := '0';
    signal start_in     : std_logic := '0';

    signal mel_addr_out : std_logic_vector(4 downto 0);
    signal mel_data_in  : std_logic_vector(31 downto 0);

    signal mem_addr_in  : std_logic_vector(2 downto 0) := (others => '0');
    signal mem_data_out : std_logic_vector(15 downto 0);

    signal ready_out    : std_logic;

    type mel_vec_t is array (0 to 31) of std_logic_vector(31 downto 0);
    type dct_vec_t is array (0 to 7) of signed(15 downto 0);

    constant mel_rom : mel_vec_t := (
        0  => x"00000001",
        1  => x"00000002",
        2  => x"00000003",
        3  => x"00000004",
        4  => x"00000005",
        5  => x"00000006",
        6  => x"00000007",
        7  => x"00000008",
        8  => x"00000009",
        9  => x"0000000A",
        10 => x"0000000B",
        11 => x"0000000C",
        12 => x"0000000D",
        13 => x"0000000E",
        14 => x"0000000F",
        15 => x"00000010",
        16 => x"00000011",
        17 => x"00000012",
        18 => x"00000013",
        19 => x"00000014",
        20 => x"00000015",
        21 => x"00000016",
        22 => x"00000017",
        23 => x"00000018",
        24 => x"00000019",
        25 => x"0000001A",
        26 => x"0000001B",
        27 => x"0000001C",
        28 => x"0000001D",
        29 => x"0000001E",
        30 => x"0000001F",
        31 => x"00000020"
    );

    constant expected_dct : dct_vec_t := (
        0 => to_signed(0,16),
        1 => to_signed(0,16),
        2 => to_signed(0,16),
        3 => to_signed(0,16),
        4 => to_signed(0,16),
        5 => to_signed(0,16),
        6 => to_signed(0,16),
        7 => to_signed(0,16)
    );

begin

    uut: entity work.Lab_DCT
        port map (
            reset_in     => reset_in,
            clock_in     => clock_in,
            mel_addr_out => mel_addr_out,
            mel_data_in  => mel_data_in,
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

    mel_rom_proc : process(mel_addr_out)
        variable idx : integer;
    begin
        idx := to_integer(unsigned(mel_addr_out));
        mel_data_in <= mel_rom(idx);
    end process;

    stim_proc : process
        variable i   : integer;
        variable got : signed(15 downto 0);
    begin
        reset_in <= '1';
        wait for 5*CLK_PERIOD;
        reset_in <= '0';
        wait for 5*CLK_PERIOD;

        start_in <= '1';
        wait for CLK_PERIOD;
        start_in <= '0';

        wait until ready_out = '1';

        for i in 0 to 7 loop
            mem_addr_in <= std_logic_vector(to_unsigned(i,3));
            wait for CLK_PERIOD;
            got := signed(mem_data_out);
            if got /= expected_dct(i) then
                report "DCT mismatch at index " & integer'image(i) &
                       " got=" & integer'image(to_integer(got)) &
                       " exp=" & integer'image(to_integer(expected_dct(i)))
                       severity error;
            else
                report "DCT match at index " & integer'image(i) &
                       " value=" & integer'image(to_integer(got))
                       severity note;
            end if;
        end loop;

        report "DCT TB finished" severity note;
        wait;
    end process;

end architecture;
