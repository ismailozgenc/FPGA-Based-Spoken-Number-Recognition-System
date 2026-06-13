library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab_DCT is
    port (
        reset_in     : in  std_logic;
        clock_in     : in  std_logic;
        mel_addr_out : out std_logic_vector(4 downto 0);
        mel_data_in  : in  std_logic_vector(31 downto 0);
        mem_addr_in  : in  std_logic_vector(2 downto 0);
        mem_data_out : out std_logic_vector(15 downto 0);
        start_in     : in  std_logic;
        ready_out    : out std_logic
    );
end entity;

architecture rtl of Lab_DCT is

    constant NUM_MEL    : integer := 32;
    constant NUM_CEPS   : integer := 13;
    constant MEL_WIDTH  : integer := 32;
    constant COEF_WIDTH : integer := 16;
    constant ACC_WIDTH  : integer := 40;
    constant FRAC_BITS  : integer := 14;

    type coeff_row_t is array (0 to NUM_MEL-1) of signed(COEF_WIDTH-1 downto 0);
    type coeff_rom_t  is array (0 to NUM_CEPS-1) of coeff_row_t;

    constant coeff_rom : coeff_rom_t := (
        0 => (to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH), to_signed(16384, COEF_WIDTH)),
        1 => (to_signed(16364, COEF_WIDTH), to_signed(16207, COEF_WIDTH), to_signed(15893, COEF_WIDTH), to_signed(15426, COEF_WIDTH), to_signed(14811, COEF_WIDTH), to_signed(14053, COEF_WIDTH), to_signed(13160, COEF_WIDTH), to_signed(12140, COEF_WIDTH), to_signed(11003, COEF_WIDTH), to_signed(9760, COEF_WIDTH), to_signed(8423, COEF_WIDTH), to_signed(7005, COEF_WIDTH), to_signed(5520, COEF_WIDTH), to_signed(3981, COEF_WIDTH), to_signed(2404, COEF_WIDTH), to_signed(804, COEF_WIDTH), to_signed(-804, COEF_WIDTH), to_signed(-2404, COEF_WIDTH), to_signed(-3981, COEF_WIDTH), to_signed(-5520, COEF_WIDTH), to_signed(-7005, COEF_WIDTH), to_signed(-8423, COEF_WIDTH), to_signed(-9760, COEF_WIDTH), to_signed(-11003, COEF_WIDTH), to_signed(-12140, COEF_WIDTH), to_signed(-13160, COEF_WIDTH), to_signed(-14053, COEF_WIDTH), to_signed(-14811, COEF_WIDTH), to_signed(-15426, COEF_WIDTH), to_signed(-15893, COEF_WIDTH), to_signed(-16207, COEF_WIDTH), to_signed(-16364, COEF_WIDTH)),
        2 => (to_signed(16305, COEF_WIDTH), to_signed(15679, COEF_WIDTH), to_signed(14449, COEF_WIDTH), to_signed(12665, COEF_WIDTH), to_signed(10394, COEF_WIDTH), to_signed(7723, COEF_WIDTH), to_signed(4756, COEF_WIDTH), to_signed(1606, COEF_WIDTH), to_signed(-1606, COEF_WIDTH), to_signed(-4756, COEF_WIDTH), to_signed(-7723, COEF_WIDTH), to_signed(-10394, COEF_WIDTH), to_signed(-12665, COEF_WIDTH), to_signed(-14449, COEF_WIDTH), to_signed(-15679, COEF_WIDTH), to_signed(-16305, COEF_WIDTH), to_signed(-16305, COEF_WIDTH), to_signed(-15679, COEF_WIDTH), to_signed(-14449, COEF_WIDTH), to_signed(-12665, COEF_WIDTH), to_signed(-10394, COEF_WIDTH), to_signed(-7723, COEF_WIDTH), to_signed(-4756, COEF_WIDTH), to_signed(-1606, COEF_WIDTH), to_signed(1606, COEF_WIDTH), to_signed(4756, COEF_WIDTH), to_signed(7723, COEF_WIDTH), to_signed(10394, COEF_WIDTH), to_signed(12665, COEF_WIDTH), to_signed(14449, COEF_WIDTH), to_signed(15679, COEF_WIDTH), to_signed(16305, COEF_WIDTH)),
        3 => (to_signed(16207, COEF_WIDTH), to_signed(14811, COEF_WIDTH), to_signed(12140, COEF_WIDTH), to_signed(8423, COEF_WIDTH), to_signed(3981, COEF_WIDTH), to_signed(-804, COEF_WIDTH), to_signed(-5520, COEF_WIDTH), to_signed(-9760, COEF_WIDTH), to_signed(-13160, COEF_WIDTH), to_signed(-15426, COEF_WIDTH), to_signed(-16364, COEF_WIDTH), to_signed(-15893, COEF_WIDTH), to_signed(-14053, COEF_WIDTH), to_signed(-11003, COEF_WIDTH), to_signed(-7005, COEF_WIDTH), to_signed(-2404, COEF_WIDTH), to_signed(2404, COEF_WIDTH), to_signed(7005, COEF_WIDTH), to_signed(11003, COEF_WIDTH), to_signed(14053, COEF_WIDTH), to_signed(15893, COEF_WIDTH), to_signed(16364, COEF_WIDTH), to_signed(15426, COEF_WIDTH), to_signed(13160, COEF_WIDTH), to_signed(9760, COEF_WIDTH), to_signed(5520, COEF_WIDTH), to_signed(804, COEF_WIDTH), to_signed(-3981, COEF_WIDTH), to_signed(-8423, COEF_WIDTH), to_signed(-12140, COEF_WIDTH), to_signed(-14811, COEF_WIDTH), to_signed(-16207, COEF_WIDTH)),
        4 => (to_signed(16069, COEF_WIDTH), to_signed(13623, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(13623, COEF_WIDTH), to_signed(16069, COEF_WIDTH), to_signed(16069, COEF_WIDTH), to_signed(13623, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(13623, COEF_WIDTH), to_signed(16069, COEF_WIDTH)),
        5 => (to_signed(15893, COEF_WIDTH), to_signed(12140, COEF_WIDTH), to_signed(5520, COEF_WIDTH), to_signed(-2404, COEF_WIDTH), to_signed(-9760, COEF_WIDTH), to_signed(-14811, COEF_WIDTH), to_signed(-16364, COEF_WIDTH), to_signed(-14053, COEF_WIDTH), to_signed(-8423, COEF_WIDTH), to_signed(-804, COEF_WIDTH), to_signed(7005, COEF_WIDTH), to_signed(13160, COEF_WIDTH), to_signed(16207, COEF_WIDTH), to_signed(15426, COEF_WIDTH), to_signed(11003, COEF_WIDTH), to_signed(3981, COEF_WIDTH), to_signed(-3981, COEF_WIDTH), to_signed(-11003, COEF_WIDTH), to_signed(-15426, COEF_WIDTH), to_signed(-16207, COEF_WIDTH), to_signed(-13160, COEF_WIDTH), to_signed(-7005, COEF_WIDTH), to_signed(804, COEF_WIDTH), to_signed(8423, COEF_WIDTH), to_signed(14053, COEF_WIDTH), to_signed(16364, COEF_WIDTH), to_signed(14811, COEF_WIDTH), to_signed(9760, COEF_WIDTH), to_signed(2404, COEF_WIDTH), to_signed(-5520, COEF_WIDTH), to_signed(-12140, COEF_WIDTH), to_signed(-15893, COEF_WIDTH)),
        6 => (to_signed(15679, COEF_WIDTH), to_signed(10394, COEF_WIDTH), to_signed(1606, COEF_WIDTH), to_signed(-7723, COEF_WIDTH), to_signed(-14449, COEF_WIDTH), to_signed(-16305, COEF_WIDTH), to_signed(-12665, COEF_WIDTH), to_signed(-4756, COEF_WIDTH), to_signed(4756, COEF_WIDTH), to_signed(12665, COEF_WIDTH), to_signed(16305, COEF_WIDTH), to_signed(14449, COEF_WIDTH), to_signed(7723, COEF_WIDTH), to_signed(-1606, COEF_WIDTH), to_signed(-10394, COEF_WIDTH), to_signed(-15679, COEF_WIDTH), to_signed(-15679, COEF_WIDTH), to_signed(-10394, COEF_WIDTH), to_signed(-1606, COEF_WIDTH), to_signed(7723, COEF_WIDTH), to_signed(14449, COEF_WIDTH), to_signed(16305, COEF_WIDTH), to_signed(12665, COEF_WIDTH), to_signed(4756, COEF_WIDTH), to_signed(-4756, COEF_WIDTH), to_signed(-12665, COEF_WIDTH), to_signed(-16305, COEF_WIDTH), to_signed(-14449, COEF_WIDTH), to_signed(-7723, COEF_WIDTH), to_signed(1606, COEF_WIDTH), to_signed(10394, COEF_WIDTH), to_signed(15679, COEF_WIDTH)),
        7 => (to_signed(15426, COEF_WIDTH), to_signed(8423, COEF_WIDTH), to_signed(-2404, COEF_WIDTH), to_signed(-12140, COEF_WIDTH), to_signed(-16364, COEF_WIDTH), to_signed(-13160, COEF_WIDTH), to_signed(-3981, COEF_WIDTH), to_signed(7005, COEF_WIDTH), to_signed(14811, COEF_WIDTH), to_signed(15893, COEF_WIDTH), to_signed(9760, COEF_WIDTH), to_signed(-804, COEF_WIDTH), to_signed(-11003, COEF_WIDTH), to_signed(-16207, COEF_WIDTH), to_signed(-14053, COEF_WIDTH), to_signed(-5520, COEF_WIDTH), to_signed(5520, COEF_WIDTH), to_signed(14053, COEF_WIDTH), to_signed(16207, COEF_WIDTH), to_signed(11003, COEF_WIDTH), to_signed(804, COEF_WIDTH), to_signed(-9760, COEF_WIDTH), to_signed(-15893, COEF_WIDTH), to_signed(-14811, COEF_WIDTH), to_signed(-7005, COEF_WIDTH), to_signed(3981, COEF_WIDTH), to_signed(13160, COEF_WIDTH), to_signed(16364, COEF_WIDTH), to_signed(12140, COEF_WIDTH), to_signed(2404, COEF_WIDTH), to_signed(-8423, COEF_WIDTH), to_signed(-15426, COEF_WIDTH)),
        8 => (to_signed(15137, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(15137, COEF_WIDTH), to_signed(15137, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(15137, COEF_WIDTH), to_signed(15137, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(15137, COEF_WIDTH), to_signed(15137, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-15137, COEF_WIDTH), to_signed(-6270, COEF_WIDTH), to_signed(6270, COEF_WIDTH), to_signed(15137, COEF_WIDTH)),
        9 => (to_signed(14811, COEF_WIDTH), to_signed(3981, COEF_WIDTH), to_signed(-9760, COEF_WIDTH), to_signed(-16364, COEF_WIDTH), to_signed(-11003, COEF_WIDTH), to_signed(2404, COEF_WIDTH), to_signed(14053, COEF_WIDTH), to_signed(15426, COEF_WIDTH), to_signed(5520, COEF_WIDTH), to_signed(-8423, COEF_WIDTH), to_signed(-16207, COEF_WIDTH), to_signed(-12140, COEF_WIDTH), to_signed(804, COEF_WIDTH), to_signed(13160, COEF_WIDTH), to_signed(15893, COEF_WIDTH), to_signed(7005, COEF_WIDTH), to_signed(-7005, COEF_WIDTH), to_signed(-15893, COEF_WIDTH), to_signed(-13160, COEF_WIDTH), to_signed(-804, COEF_WIDTH), to_signed(12140, COEF_WIDTH), to_signed(16207, COEF_WIDTH), to_signed(8423, COEF_WIDTH), to_signed(-5520, COEF_WIDTH), to_signed(-15426, COEF_WIDTH), to_signed(-14053, COEF_WIDTH), to_signed(-2404, COEF_WIDTH), to_signed(11003, COEF_WIDTH), to_signed(16364, COEF_WIDTH), to_signed(9760, COEF_WIDTH), to_signed(-3981, COEF_WIDTH), to_signed(-14811, COEF_WIDTH)),
        10 => (to_signed(14449, COEF_WIDTH), to_signed(1606, COEF_WIDTH), to_signed(-12665, COEF_WIDTH), to_signed(-15679, COEF_WIDTH), to_signed(-4756, COEF_WIDTH), to_signed(10394, COEF_WIDTH), to_signed(16305, COEF_WIDTH), to_signed(7723, COEF_WIDTH), to_signed(-7723, COEF_WIDTH), to_signed(-16305, COEF_WIDTH), to_signed(-10394, COEF_WIDTH), to_signed(4756, COEF_WIDTH), to_signed(15679, COEF_WIDTH), to_signed(12665, COEF_WIDTH), to_signed(-1606, COEF_WIDTH), to_signed(-14449, COEF_WIDTH), to_signed(-14449, COEF_WIDTH), to_signed(-1606, COEF_WIDTH), to_signed(12665, COEF_WIDTH), to_signed(15679, COEF_WIDTH), to_signed(4756, COEF_WIDTH), to_signed(-10394, COEF_WIDTH), to_signed(-16305, COEF_WIDTH), to_signed(-7723, COEF_WIDTH), to_signed(7723, COEF_WIDTH), to_signed(16305, COEF_WIDTH), to_signed(10394, COEF_WIDTH), to_signed(-4756, COEF_WIDTH), to_signed(-15679, COEF_WIDTH), to_signed(-12665, COEF_WIDTH), to_signed(1606, COEF_WIDTH), to_signed(14449, COEF_WIDTH)),
        11 => (to_signed(14053, COEF_WIDTH), to_signed(-804, COEF_WIDTH), to_signed(-14811, COEF_WIDTH), to_signed(-13160, COEF_WIDTH), to_signed(2404, COEF_WIDTH), to_signed(15426, COEF_WIDTH), to_signed(12140, COEF_WIDTH), to_signed(-3981, COEF_WIDTH), to_signed(-15893, COEF_WIDTH), to_signed(-11003, COEF_WIDTH), to_signed(5520, COEF_WIDTH), to_signed(16207, COEF_WIDTH), to_signed(9760, COEF_WIDTH), to_signed(-7005, COEF_WIDTH), to_signed(-16364, COEF_WIDTH), to_signed(-8423, COEF_WIDTH), to_signed(8423, COEF_WIDTH), to_signed(16364, COEF_WIDTH), to_signed(7005, COEF_WIDTH), to_signed(-9760, COEF_WIDTH), to_signed(-16207, COEF_WIDTH), to_signed(-5520, COEF_WIDTH), to_signed(11003, COEF_WIDTH), to_signed(15893, COEF_WIDTH), to_signed(3981, COEF_WIDTH), to_signed(-12140, COEF_WIDTH), to_signed(-15426, COEF_WIDTH), to_signed(-2404, COEF_WIDTH), to_signed(13160, COEF_WIDTH), to_signed(14811, COEF_WIDTH), to_signed(804, COEF_WIDTH), to_signed(-14053, COEF_WIDTH)),
        12 => (to_signed(13623, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(16069, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(16069, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(13623, COEF_WIDTH), to_signed(13623, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(16069, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(-13623, COEF_WIDTH), to_signed(3196, COEF_WIDTH), to_signed(16069, COEF_WIDTH), to_signed(9102, COEF_WIDTH), to_signed(-9102, COEF_WIDTH), to_signed(-16069, COEF_WIDTH), to_signed(-3196, COEF_WIDTH), to_signed(13623, COEF_WIDTH))
    );
    
    type dct_state_t is (S_IDLE, S_READ, S_ACCUM, S_NEXT_M, S_NEXT_N, S_DONE);
    signal st          : dct_state_t := S_IDLE;

    signal mel_addr_reg : std_logic_vector(4 downto 0) := (others => '0');
    signal n_idx        : integer range 0 to NUM_CEPS-1 := 0;
    signal m_idx        : integer range 0 to NUM_MEL-1 := 0;

    type ram_t is array (0 to NUM_CEPS-1) of std_logic_vector(15 downto 0);
    signal dct_ram : ram_t := (others => (others => '0'));

    signal accum : signed(ACC_WIDTH-1 downto 0) := (others => '0');

    signal mem_addr_reg : std_logic_vector(2 downto 0) := (others => '0');

begin

    mel_addr_out <= mel_addr_reg;
    mem_addr_reg <= mem_addr_in;
    mem_data_out <= dct_ram(to_integer(unsigned(mem_addr_reg)));

    process(clock_in, reset_in)
        variable mel_s  : signed(MEL_WIDTH-1 downto 0);
        variable coef_s : signed(COEF_WIDTH-1 downto 0);
        variable prod   : signed(MEL_WIDTH+COEF_WIDTH-1 downto 0);
    begin
        if reset_in = '1' then
            st           <= S_IDLE;
            ready_out    <= '1';
            mel_addr_reg <= (others => '0');
            n_idx        <= 0;
            m_idx        <= 0;
            accum        <= (others => '0');
            dct_ram      <= (others => (others => '0'));
        elsif rising_edge(clock_in) then
            case st is

                when S_IDLE =>
                    ready_out    <= '1';
                    mel_addr_reg <= (others => '0');
                    n_idx        <= 0;
                    m_idx        <= 0;
                    accum        <= (others => '0');
                    if start_in = '1' then
                        ready_out <= '0';
                        st        <= S_READ;
                    end if;

                when S_READ =>
                    mel_addr_reg <= std_logic_vector(to_unsigned(m_idx, mel_addr_reg'length));
                    st           <= S_ACCUM;

                when S_ACCUM =>
                    mel_s  := signed(mel_data_in);
                    coef_s := coeff_rom(n_idx)(m_idx);
                    prod   := mel_s * coef_s;
                    accum  <= accum + resize(prod, ACC_WIDTH);
                    st     <= S_NEXT_M;

                when S_NEXT_M =>
                    if m_idx = NUM_MEL-1 then
                        dct_ram(n_idx) <= std_logic_vector(accum(FRAC_BITS+15 downto FRAC_BITS));
                        accum          <= (others => '0');
                        m_idx          <= 0;
                        st             <= S_NEXT_N;
                    else
                        m_idx <= m_idx + 1;
                        st    <= S_READ;
                    end if;

                when S_NEXT_N =>
                    if n_idx = NUM_CEPS-1 then
                        st        <= S_DONE;
                    else
                        n_idx <= n_idx + 1;
                        st    <= S_READ;
                    end if;

                when S_DONE =>
                    ready_out <= '1';
                    if start_in = '0' then
                        st <= S_IDLE;
                    end if;

            end case;
        end if;
    end process;

end architecture;
