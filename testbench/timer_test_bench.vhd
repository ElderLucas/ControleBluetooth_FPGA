--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  TESTBANCH OF UART TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart_for_fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TIMER_TB is
end TIMER_TB;

architecture FULL of TIMER_TB is

	signal CLK           	: std_logic := '0';
	signal RST           	: std_logic := '0';
	signal timer_1seg_s 		: std_logic := '0';

	constant clk_period  : time := 20 ns;

begin

	utt: entity work.timer
	generic map (
	    CLK_FREQ   => 50e6  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)
	port map (
		clk	=> CLK,
		RST  => RST,
		TIMER_1SEG => timer_1seg_s
	);

	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;

	test_states : process
	begin
		RST <= '1';
		wait for 100 ns;
		RST <= '0';
		wait;
	end process;

end FULL;
