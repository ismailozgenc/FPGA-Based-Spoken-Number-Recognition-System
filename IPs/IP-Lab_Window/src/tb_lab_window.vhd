library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_lab_window is
end entity;

architecture sim of tb_lab_window is
  constant ADC_AW  : integer := 14;
  constant OUT_AW  : integer := 9;
  constant N       : integer := 512;

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  constant TCLK    : time := 10 ns; -- 100 MHz

  -- DUT I/O
  signal start_in      : std_logic := '0';
  signal ready_out     : std_logic;

  signal frame_addr_in : std_logic_vector(ADC_AW-1 downto 0) := (others=>'0');

  signal adc_addr_out  : std_logic_vector(ADC_AW-1 downto 0);
  signal adc_data_in   : std_logic_vector(11 downto 0);

  signal mem_addr_in   : std_logic_vector(OUT_AW-1 downto 0);
  signal mem_data_out  : std_logic_vector(19 downto 0);

  -- simple behavioral model of Lab-ADC RAM-B (16384 x 12)
  type ram12_t is array (0 to 16383) of signed(11 downto 0);
  signal adc_ram : ram12_t;

  -- reference ROM + checker
  component win_rom512x8 is
    port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      addra : in  std_logic_vector(8 downto 0);
      douta : out std_logic_vector(7 downto 0)
    );
  end component;

  signal ref_coef : std_logic_vector(7 downto 0);
  signal ref_idx  : unsigned(OUT_AW-1 downto 0) := (others=>'0');
  signal errors   : integer := 0;

begin
  -- clock
  clk <= not clk after TCLK/2;

  -- reset
  process
  begin
    rst <= '1';
    wait for 200 ns;
    rst <= '0';
    wait;
  end process;

  -- init ADC RAM region we'll read
  init_proc : process
  begin
    wait for 50 ns;
    for i in 0 to 16383 loop
      adc_ram(i) <= to_signed(0,12);
    end loop;

    -- choose base address and put a DC+small ramp so window shape is visible
    frame_addr_in <= std_logic_vector(to_unsigned(3000, ADC_AW));
    for k in 0 to N-1 loop
      adc_ram(3000+k) <= to_signed(256 + k/8, 12); -- around +256 LSB
    end loop;
    wait;
  end process;

  -- ADC RAM-B read, 1-cycle latency
  process(clk)
    variable addr : integer;
  begin
    if rising_edge(clk) then
      addr := to_integer(unsigned(adc_addr_out));
      adc_data_in <= std_logic_vector(adc_ram(addr));
    end if;
  end process;

  -- Device Under Test
  dut : entity work.lab_window
    generic map (
      FRAME_LEN_G  => N,
      ADC_ADDR_W_G => ADC_AW,
      OUT_ADDR_W_G => OUT_AW
    )
    port map (
      clock_in       => clk,
      reset_in       => rst,
      start_in       => start_in,
      ready_out      => ready_out,
      frame_addr_in  => frame_addr_in,
      adc_addr_out   => adc_addr_out,
      adc_data_in    => adc_data_in,
      mem_addr_in    => mem_addr_in,
      mem_data_out   => mem_data_out
    );

  stim : process
  -- variables live inside this process (legal place for :=)
  variable errors_v : integer := 0;
  variable adc_s    : signed(11 downto 0);
  variable coefu    : unsigned(7 downto 0);
  variable prod     : signed(19 downto 0);
  -- widened operands for clean multiply
  variable adc_s20  : signed(19 downto 0);
  variable coef_s20 : signed(19 downto 0);
begin
  wait until rst='0';
  wait for 100 ns;

  -- start the DUT
  start_in <= '1'; wait until rising_edge(clk);
  start_in <= '0';

  -- wait for completion
  wait until ready_out='1';
  report "Lab-WINDOW finished" severity note;

  -- read back and compare
  for k in 0 to N-1 loop
    -- set ROM index and output RAM address
    ref_idx     <= to_unsigned(k, OUT_AW);
    mem_addr_in <= std_logic_vector(to_unsigned(k, OUT_AW));

    -- account for ROM(1) + output RAM(1) latencies in TB path
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- expected = signed12 * unsigned8 -> signed20
    adc_s    := adc_ram(3000+k);          -- already signed(11 downto 0)
    coefu    := unsigned(ref_coef);       -- 0..255
    adc_s20  := resize(adc_s, 20);        -- sign-extend to 20
    coef_s20 := signed(resize(coefu, 20));-- ZERO-extend then view as signed (stays >= 0)
    prod     := adc_s20 * coef_s20;       -- result is signed(19 downto 0)

    if std_logic_vector(prod) /= mem_data_out then
      errors_v := errors_v + 1;
      report "Mismatch at k=" & integer'image(k) severity warning;
    end if;
  end loop;

  if errors_v = 0 then
    report "All samples match. Test PASS." severity note;
  else
    report "Errors = " & integer'image(errors_v) severity error;
  end if;

  wait;
end process;



  -- Reference coefficient ROM
  u_refrom : win_rom512x8
    port map (
      clka  => clk,
      ena   => '1',
      addra => std_logic_vector(ref_idx),
      douta => ref_coef
    );

end architecture;
