library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab_CTRL is
    generic (
        N : integer := 14;
        FRAME_LEN : integer := 256;
        ADC_MEM_DEPTH : integer := 2**14
    );
    port (
        reset_in        : in  std_logic;
        clock_in        : in  std_logic;
        start_adc_out   : out std_logic;
        ready_adc_in    : in  std_logic;
        frame_addr_out  : out std_logic_vector(N-1 downto 0);
        start_window_out: out std_logic;
        ready_window_in : in  std_logic;
        start_fft_out   : out std_logic;
        ready_fft_in    : in  std_logic;
        start_mel_out   : out std_logic;
        ready_mel_in    : in  std_logic;
        start_dct_out   : out std_logic;
        ready_dct_in    : in  std_logic;
        start_comp_out  : out std_logic;
        ready_comp_in   : in  std_logic;
        start_debug_out : out std_logic;
        ready_debug_in  : in  std_logic;
        start_in        : in  std_logic;
        ready_out       : out std_logic
    );
end entity;

architecture rtl of Lab_CTRL is
    type state_type is (
        IDLE,
        START_ADC, WAIT_ADC,
        START_WINDOW, WAIT_WINDOW,
        START_FFT, WAIT_FFT,
        START_MEL, WAIT_MEL,
        START_DCT, WAIT_DCT,
        START_COMP, WAIT_COMP,
        START_DEBUG, WAIT_DEBUG,
        INCR_ADDR,
        DONE
    );
    signal state : state_type := IDLE;
    constant HOP_SIZE  : integer := FRAME_LEN / 2;
    constant MAX_START : integer := ADC_MEM_DEPTH - FRAME_LEN;

    signal frame_addr_int : integer range 0 to ADC_MEM_DEPTH-1 := 0;

    signal start_adc_s    : std_logic := '0';
    signal start_window_s : std_logic := '0';
    signal start_fft_s    : std_logic := '0';
    signal start_mel_s    : std_logic := '0';
    signal start_dct_s    : std_logic := '0';
    signal start_comp_s   : std_logic := '0';
    signal start_debug_s  : std_logic := '0';
    signal ready_out_s    : std_logic := '1';

    signal ready_adc_ff1  : std_logic := '0';
    signal ready_adc_ff2  : std_logic := '0';
    signal ready_adc_sync : std_logic := '0';
    signal adc_seen_low   : std_logic := '0';
begin
    start_adc_out    <= start_adc_s;
    start_window_out <= start_window_s;
    start_fft_out    <= start_fft_s;
    start_mel_out    <= start_mel_s;
    start_dct_out    <= start_dct_s;
    start_comp_out   <= start_comp_s;
    start_debug_out  <= start_debug_s;
    frame_addr_out   <= std_logic_vector(to_unsigned(frame_addr_int, N));
    ready_out        <= ready_out_s;

    process(clock_in, reset_in)
    begin
        if reset_in = '1' then
            state <= IDLE;
            frame_addr_int <= 0;
            start_adc_s <= '0';
            start_window_s <= '0';
            start_fft_s <= '0';
            start_mel_s <= '0';
            start_dct_s <= '0';
            start_comp_s <= '0';
            start_debug_s <= '0';
            ready_out_s <= '1';
            ready_adc_ff1  <= '0';
            ready_adc_ff2  <= '0';
            ready_adc_sync <= '0';
            adc_seen_low   <= '0';
        elsif rising_edge(clock_in) then
            ready_adc_ff1  <= ready_adc_in;
            ready_adc_ff2  <= ready_adc_ff1;
            ready_adc_sync <= ready_adc_ff2;

            start_adc_s    <= '0';
            start_window_s <= '0';
            start_fft_s    <= '0';
            start_mel_s    <= '0';
            start_dct_s    <= '0';
            start_comp_s   <= '0';
            start_debug_s  <= '0';

            case state is
                when IDLE =>
                    ready_out_s <= '1';
                    if start_in = '1' then
                        ready_out_s    <= '0';
                        frame_addr_int <= 0;
                        state          <= START_ADC;
                    end if;

                when START_ADC =>
                    start_adc_s  <= '1';
                    if ready_adc_sync = '0' then
                        state <= WAIT_ADC;
                    end if;

                when WAIT_ADC =>
                    start_adc_s <= '1';
                    if ready_adc_sync = '1' then
                        start_adc_s <= '0';
                        state <= START_WINDOW;
                    end if;

                when START_WINDOW =>
                    start_window_s <= '1';
                    state <= WAIT_WINDOW;

                when WAIT_WINDOW =>
                    if ready_window_in = '1' then
                        state <= START_FFT;
                    end if;

                when START_FFT =>
                    start_fft_s <= '1';
                    state <= WAIT_FFT;

                when WAIT_FFT =>
                    if ready_fft_in = '1' then
                        state <= START_MEL;
                    end if;

                when START_MEL =>
                    start_mel_s <= '1';
                    state <= WAIT_MEL;

                when WAIT_MEL =>
                    if ready_mel_in = '1' then
                        state <= START_DCT;
                    end if;

                when START_DCT =>
                    start_dct_s <= '1';
                    state <= WAIT_DCT;

                when WAIT_DCT =>
                    if ready_dct_in = '1' then
                        state <= START_COMP;
                    end if;

                when START_COMP =>
                    start_comp_s <= '1';
                    state <= WAIT_COMP;

                when WAIT_COMP =>
                    if ready_comp_in = '1' then
                        state <= START_DEBUG;
                    end if;

                when START_DEBUG =>
                    start_debug_s <= '1';
                    state <= WAIT_DEBUG;

                when WAIT_DEBUG =>
                    if ready_debug_in = '1' then
                        state <= INCR_ADDR;
                    end if;

                when INCR_ADDR =>
                    if frame_addr_int + HOP_SIZE <= MAX_START then
                        frame_addr_int <= frame_addr_int + HOP_SIZE;
                        state <= START_ADC;
                    else
                        state <= DONE;
                    end if;

                when DONE =>
                    ready_out_s <= '1';
                    if start_in = '1' then
                        state <= DONE;
                    else
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture;
