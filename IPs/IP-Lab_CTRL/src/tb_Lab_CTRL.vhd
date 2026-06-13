library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Lab_CTRL is
end entity;

architecture sim of tb_Lab_CTRL is
    constant N_tb : integer := 10;
    constant FRAME_LEN_tb : integer := 32;
    constant ADC_MEM_DEPTH_tb : integer := 1024;
    signal reset_in        : std_logic := '1';
    signal clock_in        : std_logic := '0';
    signal start_adc_out   : std_logic;
    signal ready_adc_in    : std_logic := '1';
    signal frame_addr_out  : std_logic_vector(N_tb-1 downto 0);
    signal start_window_out: std_logic;
    signal ready_window_in : std_logic := '1';
    signal start_fft_out   : std_logic;
    signal ready_fft_in    : std_logic := '1';
    signal start_mel_out   : std_logic;
    signal ready_mel_in    : std_logic := '1';
    signal start_dct_out   : std_logic;
    signal ready_dct_in    : std_logic := '1';
    signal start_comp_out  : std_logic;
    signal ready_comp_in   : std_logic := '1';
    signal start_debug_out : std_logic;
    signal ready_debug_in  : std_logic := '1';
    signal start_in        : std_logic := '0';
    signal ready_out       : std_logic;
begin
    uut: entity work.Lab_CTRL
        generic map (
            N => N_tb,
            FRAME_LEN => FRAME_LEN_tb,
            ADC_MEM_DEPTH => ADC_MEM_DEPTH_tb
        )
        port map (
            reset_in => reset_in,
            clock_in => clock_in,
            start_adc_out => start_adc_out,
            ready_adc_in => ready_adc_in,
            frame_addr_out => frame_addr_out,
            start_window_out => start_window_out,
            ready_window_in => ready_window_in,
            start_fft_out => start_fft_out,
            ready_fft_in => ready_fft_in,
            start_mel_out => start_mel_out,
            ready_mel_in => ready_mel_in,
            start_dct_out => start_dct_out,
            ready_dct_in => ready_dct_in,
            start_comp_out => start_comp_out,
            ready_comp_in => ready_comp_in,
            start_debug_out => start_debug_out,
            ready_debug_in => ready_debug_in,
            start_in => start_in,
            ready_out => ready_out
        );

    clk_proc: process
    begin
        while now < 200 ms loop
            clock_in <= '0';
            wait for 5 ns;
            clock_in <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        wait for 50 ns;
        reset_in <= '0';
        wait for 50 ns;
        start_in <= '1';
        wait for 10 ns;
        start_in <= '0';
        wait for 5 ms;
        wait;
    end process;

    mock_adc: process(clock_in)
        constant LAT_adc : integer := 40;
        variable counter : integer := 0;
        variable busy : boolean := false;
    begin
        if rising_edge(clock_in) then
            if start_adc_out = '1' then
                ready_adc_in <= '0';
                busy := true;
                counter := 0;
            elsif busy = true then
                counter := counter + 1;
                if counter >= LAT_adc then
                    ready_adc_in <= '1';
                    busy := false;
                end if;
            end if;
        end if;
    end process;

    mock_window: process(clock_in)
        constant LAT_win : integer := 20;
        variable counter : integer := 0;
        variable busy : boolean := false;
    begin
        if rising_edge(clock_in) then
            if start_window_out = '1' then
                ready_window_in <= '0';
                busy := true;
                counter := 0;
            elsif busy = true then
                counter := counter + 1;
                if counter >= LAT_win then
                    ready_window_in <= '1';
                    busy := false;
                end if;
            end if;
        end if;
    end process;

    mock_fft: process(clock_in)
        constant LAT_fft : integer := 30;
        variable counter : integer := 0;
        variable busy : boolean := false;
    begin
        if rising_edge(clock_in) then
            if start_fft_out = '1' then
                ready_fft_in <= '0';
                busy := true;
                counter := 0;
            elsif busy = true then
                counter := counter + 1;
                if counter >= LAT_fft then
                    ready_fft_in <= '1';
                    busy := false;
                end if;
            end if;
        end if;
    end process;

    mock_mel: process(clock_in)
        constant LAT_mel : integer := 18;
        variable counter : integer := 0;
        variable busy : boolean := false;
    begin
        if rising_edge(clock_in) then
            if start_mel_out = '1' then
                ready_mel_in <= '0';
                busy := true;
                counter := 0;
            elsif busy = true then
                counter := counter + 1;
                if counter >= LAT_mel then
                    ready_mel_in <= '1';
                    busy := false;
                end if;
            end if;
        end if;
    end process;

    mock_dct: process(clock_in)
        constant LAT_dct : integer := 12;
        variable counter : integer := 0;
        variable busy : boolean := false;
    begin
        if rising_edge(clock_in) then
            if start_dct_out = '1' then
                ready_dct_in <= '0';
                busy := true;
                counter := 0;
            elsif busy = true then
                counter := counter + 1;
                if counter >= LAT_dct then
                    ready_dct_in <= '1';
                    busy := false;
                end if;
            end if;
        end if;
    end process;

    mock_comp: process(clock_in)
        constant LAT_comp : integer := 10;
        variable counter : integer := 0;
        variable busy : boolean := false;
    begin
        if rising_edge(clock_in) then
            if start_comp_out = '1' then
                ready_comp_in <= '0';
                busy := true;
                counter := 0;
            elsif busy = true then
                counter := counter + 1;
                if counter >= LAT_comp then
                    ready_comp_in <= '1';
                    busy := false;
                end if;
            end if;
        end if;
    end process;

    mock_debug: process(clock_in)
        constant LAT_dbg : integer := 8;
        variable counter : integer := 0;
        variable busy : boolean := false;
    begin
        if rising_edge(clock_in) then
            if start_debug_out = '1' then
                ready_debug_in <= '0';
                busy := true;
                counter := 0;
            elsif busy = true then
                counter := counter + 1;
                if counter >= LAT_dbg then
                    ready_debug_in <= '1';
                    busy := false;
                end if;
            end if;
        end if;
    end process;
end architecture;
