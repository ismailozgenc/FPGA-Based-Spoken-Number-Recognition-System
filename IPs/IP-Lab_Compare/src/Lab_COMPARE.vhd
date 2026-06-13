library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab_COMPARE is
    port (
        reset_in     : in  std_logic;
        clock_in     : in  std_logic;
        dct_addr_out : out std_logic_vector(2 downto 0);
        dct_data_in  : in  std_logic_vector(15 downto 0);
        record_in    : in  std_logic;
        number_in    : in  std_logic_vector(3 downto 0);
        seg_a        : out std_logic;
        seg_b        : out std_logic;
        seg_c        : out std_logic;
        seg_d        : out std_logic;
        seg_e        : out std_logic;
        seg_f        : out std_logic;
        seg_g        : out std_logic;
        start_in     : in  std_logic;
        ready_out    : out std_logic
    );
end entity;

architecture rtl of Lab_COMPARE is
    constant NUM_CEPS   : integer := 8;
    constant NUM_DIGITS : integer := 10;

    type state_t is (S_IDLE, S_READ_DCT, S_STORE, S_DIST_INIT, S_DIST_ACCUM, S_DONE);
    signal st : state_t := S_IDLE;

    type cep_vec_t is array (0 to NUM_CEPS-1) of signed(15 downto 0);
    type ref_ram_t is array (0 to NUM_DIGITS-1) of cep_vec_t;

    signal ref_ram  : ref_ram_t := (others => (others => (others => '0')));
    signal comp_ram : cep_vec_t := (others => (others => '0'));

    subtype dist_t is unsigned(31 downto 0);
    type dist_arr_t is array (0 to NUM_DIGITS-1) of dist_t;

    signal dist_arr : dist_arr_t := (others => (others => '0'));

    signal dct_addr_reg : std_logic_vector(2 downto 0) := (others => '0');
    signal cep_idx      : integer range 0 to NUM_CEPS-1 := 0;
    signal digit_idx    : integer range 0 to NUM_DIGITS-1 := 0;

    signal best_digit    : integer range 0 to NUM_DIGITS-1 := 0;
    signal display_digit : integer range 0 to NUM_DIGITS-1 := 0;

    signal ready_reg : std_logic := '1';
begin
    dct_addr_out <= dct_addr_reg;
    ready_out    <= ready_reg;

    process(clock_in, reset_in)
        variable dct_s   : signed(15 downto 0);
        variable ref_s   : signed(15 downto 0);
        variable comp_s  : signed(15 downto 0);
        variable diff    : signed(16 downto 0);
        variable diff2   : dist_t;
        variable min_val : dist_t;
        variable min_idx : integer range 0 to NUM_DIGITS-1;
        variable i       : integer;
    begin
        if reset_in = '1' then
            st            <= S_IDLE;
            ready_reg     <= '1';
            dct_addr_reg  <= (others => '0');
            cep_idx       <= 0;
            digit_idx     <= 0;
            ref_ram       <= (others => (others => (others => '0')));
            comp_ram      <= (others => (others => '0'));
            dist_arr      <= (others => (others => '0'));
            best_digit    <= 0;
            display_digit <= 0;
        elsif rising_edge(clock_in) then
            case st is
                when S_IDLE =>
                    ready_reg <= '1';
                    if start_in = '1' then
                        ready_reg <= '0';
                        cep_idx   <= 0;
                        digit_idx <= 0;
                        st        <= S_READ_DCT;
                    end if;

                when S_READ_DCT =>
                    dct_addr_reg <= std_logic_vector(to_unsigned(cep_idx, 3));
                    st           <= S_STORE;

                when S_STORE =>
                    dct_s := signed(dct_data_in);
                    if record_in = '1' then
                        ref_ram(to_integer(unsigned(number_in)))(cep_idx) <= dct_s;
                    else
                        comp_ram(cep_idx) <= dct_s;
                    end if;
                    if cep_idx = NUM_CEPS-1 then
                        cep_idx <= 0;
                        if record_in = '1' then
                            st <= S_DONE;
                        else
                            st <= S_DIST_INIT;
                        end if;
                    else
                        cep_idx <= cep_idx + 1;
                        st      <= S_READ_DCT;
                    end if;

                when S_DIST_INIT =>
                    dist_arr  <= (others => (others => '0'));
                    digit_idx <= 0;
                    cep_idx   <= 0;
                    st        <= S_DIST_ACCUM;

                when S_DIST_ACCUM =>
                    ref_s  := ref_ram(digit_idx)(cep_idx);
                    comp_s := comp_ram(cep_idx);
                    diff   := signed(resize(comp_s, 17)) - signed(resize(ref_s, 17));
                    diff2  := resize(unsigned(diff * diff), diff2'length);
                    dist_arr(digit_idx) <= dist_arr(digit_idx) + diff2;
                    if cep_idx = NUM_CEPS-1 then
                        cep_idx <= 0;
                        if digit_idx = NUM_DIGITS-1 then
                            min_val := dist_arr(0);
                            min_idx := 0;
                            for i in 1 to NUM_DIGITS-1 loop
                                if dist_arr(i) < min_val then
                                    min_val := dist_arr(i);
                                    min_idx := i;
                                end if;
                            end loop;
                            best_digit <= min_idx;
                            st         <= S_DONE;
                        else
                            digit_idx <= digit_idx + 1;
                            st        <= S_DIST_ACCUM;
                        end if;
                    else
                        cep_idx <= cep_idx + 1;
                        st      <= S_DIST_ACCUM;
                    end if;

                when S_DONE =>
                    ready_reg <= '1';
                    if start_in = '0' then
                        st <= S_IDLE;
                    end if;
            end case;

            if record_in = '1' then
                display_digit <= to_integer(unsigned(number_in));
            else
                display_digit <= best_digit;
            end if;
        end if;
    end process;

    with display_digit select
        seg_a <= '0' when 0 | 2 | 3 | 5 | 6 | 7 | 8 | 9,
                  '1' when others;

    with display_digit select
        seg_b <= '0' when 0 | 1 | 2 | 3 | 4 | 7 | 8 | 9,
                  '1' when others;

    with display_digit select
        seg_c <= '0' when 0 | 1 | 3 | 4 | 5 | 6 | 7 | 8 | 9,
                  '1' when others;

    with display_digit select
        seg_d <= '0' when 0 | 2 | 3 | 5 | 6 | 8 | 9,
                  '1' when others;

    with display_digit select
        seg_e <= '0' when 0 | 2 | 6 | 8,
                  '1' when others;

    with display_digit select
        seg_f <= '0' when 0 | 4 | 5 | 6 | 8 | 9,
                  '1' when others;

    with display_digit select
        seg_g <= '0' when 2 | 3 | 4 | 5 | 6 | 8 | 9,
                  '1' when others;

end architecture;
