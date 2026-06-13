----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2025 02:18:02 PM
-- Design Name: 
-- Module Name: UART - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART is
    generic (
        N : integer := 14
    );
    port (
        reset_in    : in  std_logic;
        clock_in    : in  std_logic;
        start_in    : in  std_logic;
        mem_addr_out: out std_logic_vector(N-1 downto 0);
        mem_data_in : in  std_logic_vector(31 downto 0);
        txd_out     : out std_logic;
        ready_out   : out std_logic
    );
end UART;

architecture Behavioral of UART is

    signal counter      : unsigned(15 downto 0) := (others => '0');
    signal baud_tick    : std_logic := '0';
    constant baudrate_divider : integer := 868;  -- 100MHz / 115200
    type state_type is (idle, start_bit, data, stop_bit);
    signal fsm_state    : state_type := idle;
    signal tx_shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_index    : integer range 0 to 7 := 0;
    signal byte_index   : integer range 0 to 3 := 0;

begin

    -- Baud rate generator
    process (clock_in, reset_in)
    begin
        if reset_in = '1' then
            counter   <= (others => '0');
            baud_tick <= '0';
        elsif rising_edge(clock_in) then
            if counter = baudrate_divider-1 then
                counter   <= (others => '0');
                baud_tick <= '1';
            else
                counter   <= counter + 1;
                baud_tick <= '0';
            end if;
        end if;
    end process;

    -- UART FSM
    process(clock_in, reset_in)
    begin
        if reset_in = '1' then
            fsm_state    <= idle;
            txd_out      <= '1';
            bit_index    <= 0;
            byte_index   <= 0;
            ready_out    <= '1';
            tx_shift_reg <= (others => '0');

        elsif rising_edge(clock_in) then
            if baud_tick = '1' then
                case fsm_state is

                    when idle =>
                        if start_in = '1' then
                            tx_shift_reg <= mem_data_in(7 downto 0);
                            bit_index    <= 0;
                            byte_index   <= 0;
                            fsm_state    <= start_bit;
                            ready_out    <= '0';
                        end if;

                    when start_bit =>
                        txd_out   <= '0';
                        fsm_state <= data;

                    when data =>
                        txd_out <= tx_shift_reg(bit_index);
                        if bit_index = 7 then
                            fsm_state <= stop_bit;
                        else
                            bit_index <= bit_index + 1;
                        end if;

                    when stop_bit =>
                        txd_out <= '1';
                        if byte_index < 3 then
                            byte_index <= byte_index + 1;
                            bit_index  <= 0;
                            case byte_index+1 is
                                when 1 => tx_shift_reg <= mem_data_in(15 downto 8);
                                when 2 => tx_shift_reg <= mem_data_in(23 downto 16);
                                when 3 => tx_shift_reg <= mem_data_in(31 downto 24);
                                when others => null;
                            end case;
                            fsm_state <= start_bit;
                        else
                            ready_out <= '1';
                            fsm_state <= idle;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;
