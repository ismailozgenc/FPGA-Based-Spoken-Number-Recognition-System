library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab_FFT is
    port (
        reset_in  : in  std_logic;
        clock_in  : in  std_logic;
        addr_out  : out std_logic_vector(8 downto 0);
        data_in   : in  std_logic_vector(19 downto 0);
        addr_in   : in  std_logic_vector(7 downto 0);
        data_out  : out std_logic_vector(31 downto 0);
        start_in  : in  std_logic;
        ready_out : out std_logic
    );
end entity;

architecture rtl of Lab_FFT is

    component xfft_0 is
        port (
            aclk                 : in  std_logic;
            aresetn              : in  std_logic;
            s_axis_config_tdata  : in  std_logic_vector(7 downto 0);
            s_axis_config_tvalid : in  std_logic;
            s_axis_config_tready : out std_logic;
            s_axis_data_tdata    : in  std_logic_vector(47 downto 0);
            s_axis_data_tvalid   : in  std_logic;
            s_axis_data_tready   : out std_logic;
            s_axis_data_tlast    : in  std_logic;
            m_axis_data_tdata    : out std_logic_vector(63 downto 0);
            m_axis_data_tvalid   : out std_logic;
            m_axis_data_tlast    : out std_logic;
            event_frame_started  : out std_logic;
            event_tlast_unexpected : out std_logic;
            event_tlast_missing  : out std_logic;
            event_data_in_channel_halt : out std_logic
        );
    end component;

    type fft_state_t is (S_IDLE, S_CFG, S_LOAD, S_WAIT_OUT, S_STORE, S_DONE);
    signal st           : fft_state_t := S_IDLE;

    signal aresetn      : std_logic := '0';

    signal cfg_tdata    : std_logic_vector(7 downto 0) := (others => '0');
    signal cfg_tvalid   : std_logic := '0';
    signal cfg_tready   : std_logic;

    signal din_tdata    : std_logic_vector(47 downto 0) := (others => '0');
    signal din_tvalid   : std_logic := '0';
    signal din_tready   : std_logic;
    signal din_tlast    : std_logic := '0';

    signal dout_tdata   : std_logic_vector(63 downto 0);
    signal dout_tvalid  : std_logic;
    signal dout_tlast   : std_logic;

    signal event_frame_started        : std_logic;
    signal event_tlast_unexpected     : std_logic;
    signal event_tlast_missing        : std_logic;
    signal event_data_in_channel_halt : std_logic;

    type ram_t is array (0 to 255) of std_logic_vector(31 downto 0);
    signal fft_ram : ram_t := (others => (others => '0'));

    signal sample_idx : integer range 0 to 511 := 0;
    signal out_idx    : integer range 0 to 511 := 0;

    signal addr_out_reg : std_logic_vector(8 downto 0) := (others => '0');
    signal addr_in_reg  : std_logic_vector(7 downto 0) := (others => '0');

    signal sample_pipe  : std_logic_vector(19 downto 0) := (others => '0');

begin

    addr_out <= addr_out_reg;
    addr_in_reg <= addr_in;
    data_out <= fft_ram(to_integer(unsigned(addr_in_reg)));

    u_fft: xfft_0
        port map (
            aclk                 => clock_in,
            aresetn              => aresetn,
            s_axis_config_tdata  => cfg_tdata,
            s_axis_config_tvalid => cfg_tvalid,
            s_axis_config_tready => cfg_tready,
            s_axis_data_tdata    => din_tdata,
            s_axis_data_tvalid   => din_tvalid,
            s_axis_data_tready   => din_tready,
            s_axis_data_tlast    => din_tlast,
            m_axis_data_tdata    => dout_tdata,
            m_axis_data_tvalid   => dout_tvalid,
            m_axis_data_tlast    => dout_tlast,
            event_frame_started  => event_frame_started,
            event_tlast_unexpected => event_tlast_unexpected,
            event_tlast_missing  => event_tlast_missing,
            event_data_in_channel_halt => event_data_in_channel_halt
        );

    process(clock_in, reset_in)
        variable re_s  : signed(29 downto 0);
        variable im_s  : signed(29 downto 0);
        variable re2   : signed(59 downto 0);
        variable im2   : signed(59 downto 0);
        variable mag2  : signed(60 downto 0);
    begin
        if reset_in = '1' then
            aresetn       <= '0';
            st            <= S_IDLE;
            ready_out     <= '1';
            cfg_tdata     <= (others => '0');
            cfg_tvalid    <= '0';
            din_tdata     <= (others => '0');
            din_tvalid    <= '0';
            din_tlast     <= '0';
            sample_idx    <= 0;
            out_idx       <= 0;
            addr_out_reg  <= (others => '0');
            sample_pipe   <= (others => '0');
        elsif rising_edge(clock_in) then
            aresetn <= '1';
            cfg_tvalid <= '0';
            din_tvalid <= '0';
            din_tlast  <= '0';

            case st is

                when S_IDLE =>
                    ready_out <= '1';
                    sample_idx <= 0;
                    out_idx    <= 0;
                    addr_out_reg <= (others => '0');
                    if start_in = '1' then
                        ready_out <= '0';
                        cfg_tdata <= x"01";
                        cfg_tvalid <= '1';
                        st <= S_CFG;
                    end if;

                when S_CFG =>
                    ready_out <= '0';
                    cfg_tdata <= x"01";
                    cfg_tvalid <= '1';
                    if cfg_tready = '1' then
                        sample_idx <= 0;
                        addr_out_reg <= (others => '0');
                        st <= S_LOAD;
                    end if;

                when S_LOAD =>
                    ready_out <= '0';
                    sample_pipe <= data_in;
                    addr_out_reg <= std_logic_vector(unsigned(addr_out_reg) + 1);
                    if din_tready = '1' then
                        din_tdata(19 downto 0)  <= sample_pipe;
                        din_tdata(23 downto 20) <= (others => sample_pipe(19));
                        din_tdata(43 downto 24) <= (others => '0');
                        din_tdata(47 downto 44) <= (others => '0');
                        din_tvalid <= '1';
                        if sample_idx = 511 then
                            din_tlast  <= '1';
                            st <= S_WAIT_OUT;
                        end if;
                        if sample_idx < 511 then
                            sample_idx <= sample_idx + 1;
                        end if;
                    end if;

                when S_WAIT_OUT =>
                    ready_out <= '0';
                    if dout_tvalid = '1' then
                        out_idx <= 0;
                        st <= S_STORE;
                    end if;

                when S_STORE =>
                    ready_out <= '0';
                    if dout_tvalid = '1' then
                        re_s := signed(dout_tdata(29 downto 0));
                        im_s := signed(dout_tdata(61 downto 32));
                        re2 := re_s * re_s;
                        im2 := im_s * im_s;
                        mag2 := resize(re2, 61) + resize(im2, 61);
                        if out_idx < 256 then
                            fft_ram(out_idx) <= std_logic_vector(mag2(60 downto 29));
                            out_idx <= out_idx + 1;
                        end if;
                        if dout_tlast = '1' then
                            st <= S_DONE;
                        end if;
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
