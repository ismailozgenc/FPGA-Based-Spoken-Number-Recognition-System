library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab_ADC_core is
    generic (
        N                 : integer := 14;
        DECIM_FACTOR      : integer := 32;
        ADC_WORD          : integer := 12;
        ADC_OFFSET        : integer := 2048;
        VOICE_THRESH      : integer := 300;
        SILENCE_LIMIT     : integer := 160;
        CS_LOW_CYCLES     : integer := 16;
        CS_PERIOD_CYCLES  : integer := 32
    );
    port (
        reset_in     : in  std_logic;
        spi_clk_in   : in  std_logic;
        start_in     : in  std_logic;
        spi_data_in  : in  std_logic;
        spi_clk_out  : out std_logic;
        chip_sel_out : out std_logic;
        bram_a_we    : out std_logic;
        bram_a_addr  : out std_logic_vector(N-1 downto 0);
        bram_a_din   : out std_logic_vector(ADC_WORD-1 downto 0);
        ready_out    : out std_logic
    );
end entity;

architecture rtl of Lab_ADC_core is
    signal spi_shift     : std_logic_vector(ADC_WORD-1 downto 0) := (others => '0');
    signal bit_count     : integer range 0 to 15 := 0;

    signal decim_acc     : signed(19 downto 0) := (others => '0');
    signal decim_count   : integer range 0 to DECIM_FACTOR-1 := 0;
    signal avg_int       : integer := 0;
    signal avg_reg       : signed(ADC_WORD-1 downto 0) := (others => '0');

    signal write_addr    : unsigned(N-1 downto 0) := (others => '0');
    constant MAX_ADDR    : integer := 2**N - 1;

    signal started       : std_logic := '0';
    signal in_voice      : std_logic := '0';
    signal silence_count : integer := 0;

    signal bram_we_s     : std_logic := '0';
    signal bram_addr_s   : unsigned(N-1 downto 0) := (others => '0');
    signal bram_din_s    : std_logic_vector(ADC_WORD-1 downto 0) := (others => '0');

    signal write_pending : std_logic := '0';
    signal filling_zeros : std_logic := '0';

    signal start_ff1     : std_logic := '0';
    signal start_ff2     : std_logic := '0';
    signal start_pulse   : std_logic := '0';

    signal cs_cnt        : integer range 0 to CS_PERIOD_CYCLES-1 := 0;
    signal cs_low_left   : integer range 0 to CS_LOW_CYCLES := 0;
    signal cs_int        : std_logic := '1';
begin
    spi_clk_out <= spi_clk_in;

    bram_a_we   <= bram_we_s;
    bram_a_addr <= std_logic_vector(bram_addr_s);
    bram_a_din  <= bram_din_s;

    ready_out    <= '1' when (started = '0') else '0';
    chip_sel_out <= cs_int;

    process(reset_in, spi_clk_in)
    begin
        if reset_in = '1' then
            cs_cnt      <= 0;
            cs_low_left <= 0;
            cs_int      <= '1';
        elsif rising_edge(spi_clk_in) then
            if cs_cnt = CS_PERIOD_CYCLES-1 then
                cs_cnt      <= 0;
                cs_low_left <= CS_LOW_CYCLES;
                cs_int      <= '0';
            else
                cs_cnt <= cs_cnt + 1;
                if cs_low_left > 0 then
                    cs_low_left <= cs_low_left - 1;
                    if cs_low_left = 1 then
                        cs_int <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(reset_in, spi_clk_in)
        variable unsigned_sample_int : integer;
        variable signed_sample_int   : integer;
        variable shift_var           : std_logic_vector(ADC_WORD-1 downto 0);
        variable sum_var             : signed(decim_acc'range);
        variable avg_var             : integer;
    begin
        if reset_in = '1' then
            spi_shift     <= (others => '0');
            bit_count     <= 0;
            decim_acc     <= (others => '0');
            decim_count   <= 0;
            avg_int       <= 0;
            bram_we_s     <= '0';
            bram_addr_s   <= (others => '0');
            bram_din_s    <= (others => '0');
            write_addr    <= (others => '0');
            write_pending <= '0';
            filling_zeros <= '0';
            started       <= '0';
            in_voice      <= '0';
            silence_count <= 0;
            start_ff1     <= '0';
            start_ff2     <= '0';
            start_pulse   <= '0';
        elsif falling_edge(spi_clk_in) then
            bram_we_s <= '0';

            start_ff1   <= start_in;
            start_ff2   <= start_ff1;
            start_pulse <= start_ff1 and not start_ff2;

            if start_pulse = '1' and started = '0' then
                started       <= '1';
                in_voice      <= '0';
                silence_count <= 0;
                write_addr    <= (others => '0');
                write_pending <= '0';
                filling_zeros <= '0';
                decim_acc     <= (others => '0');
                decim_count   <= 0;
            end if;

            if write_pending = '1' then
                bram_addr_s <= write_addr;
                bram_din_s  <= std_logic_vector(avg_reg);
                bram_we_s   <= '1';
                if to_integer(write_addr) < MAX_ADDR then
                    write_addr <= write_addr + 1;
                else
                    started <= '0';
                end if;
                write_pending <= '0';
            elsif filling_zeros = '1' then
                bram_addr_s <= write_addr;
                bram_din_s  <= (others => '0');
                bram_we_s   <= '1';
                if to_integer(write_addr) < MAX_ADDR then
                    write_addr <= write_addr + 1;
                else
                    filling_zeros <= '0';
                    started       <= '0';
                end if;
            end if;

            if cs_int = '0' then
                shift_var := spi_shift(ADC_WORD-2 downto 0) & spi_data_in;
                spi_shift <= shift_var;

                if bit_count < 15 then
                    bit_count <= bit_count + 1;
                else
                    bit_count <= 0;

                    unsigned_sample_int := to_integer(unsigned(shift_var));
                    signed_sample_int   := unsigned_sample_int - ADC_OFFSET;
                    decim_acc <= decim_acc + to_signed(signed_sample_int, decim_acc'length);

                    if decim_count = DECIM_FACTOR-1 then
                        sum_var := decim_acc + to_signed(signed_sample_int, decim_acc'length);
                        decim_acc   <= (others => '0');
                        decim_count <= 0;

                        avg_var := to_integer(sum_var) / DECIM_FACTOR;
                        avg_int <= avg_var;
                        avg_reg <= resize(to_signed(avg_var, ADC_WORD), avg_reg'length);

                        if abs(avg_var) >= VOICE_THRESH then
                            in_voice      <= '1';
                            silence_count <= 0;
                        else
                            if in_voice = '1' then
                                silence_count <= silence_count + 1;
                                if silence_count >= SILENCE_LIMIT then
                                    in_voice      <= '0';
                                    filling_zeros <= '1';
                                end if;
                            end if;
                        end if;

                        if started = '1' and (in_voice = '1' or abs(avg_var) >= VOICE_THRESH) then
                            if filling_zeros = '0' then
                                write_pending <= '1';
                            end if;
                        end if;
                    else
                        decim_count <= decim_count + 1;
                    end if;
                end if;
            end if;

            if to_integer(write_addr) > MAX_ADDR then
                started <= '0';
                filling_zeros <= '0';
            end if;
        end if;
    end process;
end architecture;
