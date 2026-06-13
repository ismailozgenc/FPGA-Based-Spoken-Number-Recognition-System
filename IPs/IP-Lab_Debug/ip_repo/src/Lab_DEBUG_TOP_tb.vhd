library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab_DEBUG_TOP_tb is
end Lab_DEBUG_TOP_tb;

architecture Behavioral of Lab_DEBUG_TOP_tb is
    signal reset_in  : std_logic := '0';
    signal clock_in  : std_logic := '0';
    signal start_in  : std_logic := '0';
    signal txd_out   : std_logic;
    signal ready_out : std_logic;

begin

    uut: entity work.Lab_Debug_top
        generic map (N => 14)  
        port map (
            reset_in  => reset_in,
            clock_in  => clock_in,
            start_in  => start_in,
            txd_out   => txd_out,
            ready_out => ready_out
        );

    clk_process : process
    begin
        while true loop
            clock_in <= '0';
            wait for 5 ns;
            clock_in <= '1';
            wait for 5 ns;
        end loop;
    end process;

    stim_proc: process
    begin
        reset_in <= '1';
        wait for 50 ns;
        reset_in <= '0';
        wait for 50 ns;

        start_in <= '1';
        wait for 10 us;   
        start_in <= '0';

        wait;
    end process;

end Behavioral;