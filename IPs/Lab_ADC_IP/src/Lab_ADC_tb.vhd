library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab_ADC_tb is
end entity;

architecture tb of Lab_ADC_tb is
    constant N_tb            : integer := 8;
    constant DECIM_tb        : integer := 4;
    constant ADC_WORD_tb     : integer := 12;
    constant ADC_OFFSET_tb   : integer := 2048;
    constant VOICE_THRESH_tb : integer := 50;
    constant SILENCE_LIM_tb  : integer := 2;

    signal reset_in    : std_logic := '1';
    signal clock_in    : std_logic := '0';
    signal spi_clk_in  : std_logic := '0';
    signal start_in    : std_logic := '0';
    signal spi_data_in : std_logic := '0';
    signal spi_clk_out : std_logic;
    signal chip_sel_out: std_logic;
    signal bram_a_we   : std_logic;
    signal bram_a_addr : std_logic_vector(N_tb-1 downto 0);
    signal bram_a_din  : std_logic_vector(ADC_WORD_tb-1 downto 0);
    signal ready_out   : std_logic;

    type addr_array is array (natural range <>) of integer;
    type data_array is array (natural range <>) of std_logic_vector(ADC_WORD_tb-1 downto 0);

    signal written_addrs : addr_array(0 to 1023) := (others => 0);
    signal written_data  : data_array(0 to 1023) := (others => (others => '0'));
    signal write_cnt     : integer := 0;

    constant DECIM_SAMPLES_TO_RECORD : integer := 8;
    constant SAMPLE_VOICE_OFFSET     : integer := 100;
    constant SAMPLE_SILENCE_OFFSET   : integer := 0;

    signal we_d : std_logic := '0';

    function slv_to_integer(x: std_logic_vector) return integer is
    begin
        return to_integer(signed(x));
    end function;
begin
    DUT: entity work.Lab_ADC_core
        generic map (
            N => N_tb,
            DECIM_FACTOR => DECIM_tb,
            ADC_WORD => ADC_WORD_tb,
            ADC_OFFSET => ADC_OFFSET_tb,
            VOICE_THRESH => VOICE_THRESH_tb,
            SILENCE_LIMIT => SILENCE_LIM_tb,
            CS_LOW_CYCLES => 16,
            CS_PERIOD_CYCLES => 32
        )
        port map (
            reset_in => reset_in,
            clock_in => clock_in,
            spi_clk_in => spi_clk_in,
            start_in => start_in,
            spi_data_in => spi_data_in,
            spi_clk_out => spi_clk_out,
            chip_sel_out => chip_sel_out,
            bram_a_we => bram_a_we,
            bram_a_addr => bram_a_addr,
            bram_a_din => bram_a_din,
            ready_out => ready_out
        );

    clk_proc : process
    begin
        wait for 5 ns;
        clock_in <= not clock_in;
    end process;

    spi_clk_proc : process
    begin
        spi_clk_in <= '0';
        wait for 31.25 ns;
        spi_clk_in <= '1';
        wait for 31.25 ns;
    end process;

    stim_proc : process
        variable i_win      : integer;
        variable bit_i      : integer;
        variable sample_val : integer;
        variable sample_bits: std_logic_vector(ADC_WORD_tb-1 downto 0);
        variable expected_val: integer;
        variable total_conversions : integer;
        variable got        : integer;
        variable limit      : integer;
    begin
        wait for 100 ns;
        reset_in <= '0';
        wait for 50 ns;

        start_in <= '1';
        wait for 200 ns;
        start_in <= '0';

        sample_val  := ADC_OFFSET_tb + SAMPLE_VOICE_OFFSET;
        sample_bits := std_logic_vector(to_unsigned(sample_val, ADC_WORD_tb));
        total_conversions := DECIM_SAMPLES_TO_RECORD * DECIM_tb;

        for i_win in 0 to total_conversions - 1 loop
            wait until chip_sel_out = '0';
            wait for 1 ns;
            for bit_i in 3 downto 0 loop
                wait until falling_edge(spi_clk_in);
                spi_data_in <= '0';
                wait until rising_edge(spi_clk_in);
            end loop;
            for bit_i in ADC_WORD_tb-1 downto 0 loop
                wait until falling_edge(spi_clk_in);
                spi_data_in <= sample_bits(bit_i);
                wait until rising_edge(spi_clk_in);
            end loop;
            wait until chip_sel_out = '1';
            spi_data_in <= '0';
            wait for 2 ns;
        end loop;

        sample_val  := ADC_OFFSET_tb + SAMPLE_SILENCE_OFFSET;
        sample_bits := std_logic_vector(to_unsigned(sample_val, ADC_WORD_tb));

        for i_win in 0 to SILENCE_LIM_tb loop
            wait until chip_sel_out = '0';
            wait for 1 ns;
            for bit_i in 3 downto 0 loop
                wait until falling_edge(spi_clk_in);
                spi_data_in <= '0';
                wait until rising_edge(spi_clk_in);
            end loop;
            for bit_i in ADC_WORD_tb-1 downto 0 loop
                wait until falling_edge(spi_clk_in);
                spi_data_in <= sample_bits(bit_i);
                wait until rising_edge(spi_clk_in);
            end loop;
            wait until chip_sel_out = '1';
            spi_data_in <= '0';
            wait for 2 ns;
        end loop;

        wait until ready_out = '1';

        report "Captured write_cnt = " & integer'image(write_cnt);

        if write_cnt <= 0 then
            limit := -1;
        else
            limit := write_cnt - 1;
        end if;
        if limit > (DECIM_SAMPLES_TO_RECORD - 1) then
            limit := DECIM_SAMPLES_TO_RECORD - 1;
        end if;

        if limit >= 0 then
            for i_win in 0 to limit loop
                report "write[" & integer'image(i_win) & "] addr=" & integer'image(written_addrs(i_win)) &
                       " data=" & integer'image(slv_to_integer(written_data(i_win)));
            end loop;
        end if;

        if write_cnt < DECIM_SAMPLES_TO_RECORD then
            assert false report "FAIL: fewer than expected decimated writes. write_cnt=" & integer'image(write_cnt)
                severity failure;
        end if;

        expected_val := SAMPLE_VOICE_OFFSET;

        for i_win in 0 to DECIM_SAMPLES_TO_RECORD - 1 loop
            got := slv_to_integer(written_data(i_win));
            if got /= expected_val then
                assert false report "FAIL: decimated sample " & integer'image(i_win) &
                    " expected=" & integer'image(expected_val) & " got=" & integer'image(got)
                    severity failure;
            end if;
        end loop;

        report "PASS: All first " & integer'image(DECIM_SAMPLES_TO_RECORD) &
               " decimated samples match expected value " & integer'image(expected_val);
        wait;
    end process;

    monitor_proc : process(spi_clk_in)
    begin
        if rising_edge(spi_clk_in) then
            if bram_a_we = '1' and we_d = '0' then
                if write_cnt <= 1023 then
                    written_addrs(write_cnt) <= to_integer(unsigned(bram_a_addr));
                    written_data(write_cnt)  <= bram_a_din;
                    write_cnt <= write_cnt + 1;
                end if;
            end if;
            we_d <= bram_a_we;
        end if;
    end process;
end architecture;
