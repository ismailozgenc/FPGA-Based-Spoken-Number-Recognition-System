library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab_Debug_top is
    generic (
        N : integer := 14
    );
    port (
        reset_in    : in  std_logic;
        clock_in    : in  std_logic;
        start_in    : in  std_logic;
        txd_out     : out std_logic;
        ready_out   : out std_logic;
        mem_addr_out: out std_logic_vector(N-1 downto 0);
        mem_data_in : in  std_logic_vector(31 downto 0)
    );
end Lab_Debug_top;

architecture Behavioral of Lab_Debug_top is

    signal rom_data_reg  : std_logic_vector(31 downto 0);

    signal uart_start    : std_logic := '0';
    signal uart_ready    : std_logic;
    signal uart_data     : std_logic_vector(31 downto 0);

    signal mem_index     : unsigned(N-1 downto 0) := (others => '0');
    constant DATA_COUNT  : integer := 4;

    type state_type is (
        IDLE,
        WAIT_STARTED,
        WAIT_DONE, 
        ROM_WAIT,
        ROM_WAIT_LATENCY,
        SEND_INIT
    );
    signal state : state_type := IDLE;

    type action_type is (ACT_NONE, ACT_START, ACT_MEM, ACT_STOP);
    signal action : action_type := ACT_NONE;

    constant START_WORD : std_logic_vector(31 downto 0) := x"55AACC03";
    constant STOP_WORD  : std_logic_vector(31 downto 0) := x"AA5503CC";

    constant MAX_ADDR : unsigned(N-1 downto 0) := (others => '1');

    signal send_last : std_logic := '0';

begin

    mem_addr_out <= std_logic_vector(mem_index);

    UART_INST : entity work.UART
        generic map ( N => N )
        port map (
            reset_in     => reset_in,
            clock_in     => clock_in,
            start_in     => uart_start,
            mem_addr_out => open,
            mem_data_in  => uart_data,
            txd_out      => txd_out,
            ready_out    => uart_ready
        );

    process(clock_in, reset_in)
    begin
        if reset_in = '1' then
            state        <= IDLE;
            action       <= ACT_NONE;
            mem_index    <= (others => '0');
            rom_data_reg <= (others => '0');
            uart_data    <= (others => '0');
            uart_start   <= '0';
            ready_out    <= '1';
            send_last    <= '0';

        elsif rising_edge(clock_in) then

            uart_start <= '0';

            case state is
                when IDLE =>
                    ready_out <= '1';
                    action <= ACT_NONE;
                    if start_in = '1' then
                        uart_data  <= START_WORD;
                        action     <= ACT_START;
                        ready_out  <= '0';
                        state      <= WAIT_STARTED;
                    end if;

                when WAIT_STARTED =>
                    uart_start <= '1';
                    if uart_ready = '0' then
                        uart_start <= '0';
                        state <= WAIT_DONE;
                    end if;

                when WAIT_DONE =>
                    if uart_ready = '1' then
                        if action = ACT_START then
                            mem_index <= (others => '0');
                            state <= ROM_WAIT;
                        elsif action = ACT_MEM then
                            if send_last = '1' then
                                uart_data <= STOP_WORD;
                                action    <= ACT_STOP;
                                send_last <= '0';
                                state     <= WAIT_STARTED;
                            else
                                state <= ROM_WAIT;
                            end if;
                        elsif action = ACT_STOP then
                            ready_out <= '1';
                            action <= ACT_NONE;
                            state <= IDLE;
                        else
                            state <= IDLE;
                        end if;
                    end if;

                when ROM_WAIT =>
                    state <= ROM_WAIT_LATENCY;
                
                when ROM_WAIT_LATENCY =>
                    rom_data_reg <= mem_data_in;
                    state <= SEND_INIT;

                when SEND_INIT =>
                    uart_data <= rom_data_reg;
                    action <= ACT_MEM;
                    if mem_index = MAX_ADDR then
                        send_last <= '1';
                        state <= WAIT_STARTED;
                    else
                        mem_index <= mem_index + 1;
                        state <= WAIT_STARTED;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;
