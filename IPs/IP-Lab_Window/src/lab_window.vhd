-- lab_window.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab_window is
  generic (
    FRAME_LEN_G  : integer := 512;  -- window length
    ADC_ADDR_W_G : integer := 14;   -- Lab-ADC Port-B address width (16384 -> 14)
    OUT_ADDR_W_G : integer := 9     -- log2(512) = 9
  );
  port (
    -- board clock/reset
    clock_in       : in  std_logic; -- 100 MHz
    reset_in       : in  std_logic; -- sync, active-high

    -- control
    start_in       : in  std_logic; -- one-cycle pulse
    ready_out      : out std_logic; -- '1' when idle/done

    -- frame start addr in Lab-ADC RAM-B
    frame_addr_in  : in  std_logic_vector(ADC_ADDR_W_G-1 downto 0);

    -- Lab-ADC RAM-B interface (read-only here)
    adc_addr_out   : out std_logic_vector(ADC_ADDR_W_G-1 downto 0);
    adc_data_in    : in  std_logic_vector(11 downto 0);   -- signed 12b

    -- Lab-WINDOW RAM interface (Port-B read-only for downstream)
    mem_addr_in    : in  std_logic_vector(OUT_ADDR_W_G-1 downto 0);
    mem_data_out   : out std_logic_vector(19 downto 0)    -- signed 20b
  );
end entity;

architecture rtl of lab_window is

  component win_rom512x8 is
    port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      addra : in  std_logic_vector(8 downto 0);
      douta : out std_logic_vector(7 downto 0)
    );
  end component;

  component win_mult12x8 is
    port (
      A   : in  std_logic_vector(11 downto 0); -- signed
      B   : in  std_logic_vector(7 downto 0);  -- unsigned
      CLK : in  std_logic;
      P   : out std_logic_vector(19 downto 0)  -- signed product
    );
  end component;

  component win_ram512x20 is
    port (
      -- Port-A : write
      clka  : in  std_logic;
      ena   : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(8 downto 0);
      dina  : in  std_logic_vector(19 downto 0);
      -- Port-B : read
      clkb  : in  std_logic;
      enb   : in  std_logic;
      addrb : in  std_logic_vector(8 downto 0);
      doutb : out std_logic_vector(19 downto 0)
    );
  end component;

  type state_t is (IDLE, RUN, DRAIN);
  signal st        : state_t := IDLE;

  signal ready_q   : std_logic := '1';

  signal base_addr : unsigned(ADC_ADDR_W_G-1 downto 0) := (others=>'0');
  signal idx_addr  : unsigned(OUT_ADDR_W_G-1 downto 0) := (others=>'0'); -- 0..FRAME_LEN_G-1

  constant PIPE_CYC : integer := 2;  -- 1 input reg + 1 mult reg

  type idx_arr_t is array (0 to PIPE_CYC-1) of unsigned(OUT_ADDR_W_G-1 downto 0);
  signal idx_pipe  : idx_arr_t := (others=>(others=>'0'));
  signal vld_pipe  : std_logic_vector(PIPE_CYC-1 downto 0) := (others=>'0');

  signal rom_dout  : std_logic_vector(7 downto 0);
  signal adc_q     : signed(11 downto 0) := (others=>'0');
  signal coef_q    : unsigned(7 downto 0) := (others=>'0');

  signal prod_d    : std_logic_vector(19 downto 0);
  signal prod_q    : std_logic_vector(19 downto 0) := (others=>'0');

  signal we_a      : std_logic_vector(0 downto 0) := (others=>'0');

begin
  ready_out <= ready_q;

  u_rom : win_rom512x8
    port map (
      clka  => clock_in,
      ena   => '1',
      addra => std_logic_vector(idx_addr),
      douta => rom_dout
    );

  process(clock_in)
  begin
    if rising_edge(clock_in) then
      adc_q  <= signed(adc_data_in);      -- sign-preserve
      coef_q <= unsigned(rom_dout);       -- 0..255
    end if;
  end process;

  u_mul : win_mult12x8
    port map (
      A   => std_logic_vector(adc_q),
      B   => std_logic_vector(coef_q),
      CLK => clock_in,
      P   => prod_d
    );

  process(clock_in)
  begin
    if rising_edge(clock_in) then
      prod_q <= prod_d;
    end if;
  end process;

  u_ram : win_ram512x20
    port map (
      clka  => clock_in,
      ena   => '1',
      wea   => we_a,
      addra => std_logic_vector(idx_pipe(PIPE_CYC-1)),
      dina  => prod_q,

      clkb  => clock_in,
      enb   => '1',
      addrb => mem_addr_in,
      doutb => mem_data_out
    );

  adc_addr_out <= std_logic_vector(base_addr + resize(idx_addr, base_addr'length));

  process(clock_in)
  begin
    if rising_edge(clock_in) then
      if reset_in = '1' then
        st        <= IDLE;
        ready_q   <= '1';
        idx_addr  <= (others=>'0');
        base_addr <= (others=>'0');
        idx_pipe  <= (others=>(others=>'0'));
        vld_pipe  <= (others=>'0');
        we_a      <= (others=>'0');
      else
        we_a <= (others=>'0');

        -- shift pipes
        idx_pipe(0) <= idx_addr;
        for i in 1 to PIPE_CYC-1 loop
          idx_pipe(i) <= idx_pipe(i-1);
        end loop;
        vld_pipe(0) <= '0';
        for i in 1 to PIPE_CYC-1 loop
          vld_pipe(i) <= vld_pipe(i-1);
        end loop;

        case st is
          when IDLE =>
            ready_q <= '1';
            if start_in = '1' then
              base_addr <= unsigned(frame_addr_in);
              idx_addr  <= (others=>'0');
              vld_pipe(0) <= '1';         -- launch first valid
              ready_q   <= '0';
              st        <= RUN;
            end if;

          when RUN =>
            vld_pipe(0) <= '1';           -- launch continuous valids
            if vld_pipe(PIPE_CYC-1) = '1' then
              we_a(0) <= '1';
            end if;
            if idx_addr = to_unsigned(FRAME_LEN_G-1, idx_addr'length) then
              st <= DRAIN;
            else
              idx_addr <= idx_addr + 1;
            end if;

          when DRAIN =>
            if vld_pipe(PIPE_CYC-1) = '1' then
              we_a(0) <= '1';
            end if;
            if vld_pipe = (vld_pipe'range => '0') then
              ready_q <= '1';
              st      <= IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;

end architecture;