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

entity TOPO_TB is
end TOPO_TB;

architecture FULL of TOPO_TB is

	signal CLK           	: std_logic := '0';
	signal RST           	: std_logic := '0';

    signal led_out_s 	    :std_logic_vector(7 downto 0);
    signal SCLK_OUT_s           	: std_logic := '0';
    signal SS_OUT_s           	: std_logic := '0';
    signal MOSI_OUT_s           	: std_logic := '0';
    signal MISO_IN_s           	: std_logic := '0';

    constant clk_period  : time := 20 ns;

begin

	utt: entity work.topo
	generic map (
        CLK_FREQ    => 50e6,
        BAUD_RATE   => 115200,
        PARITY_BIT  => "none"
    )
	port map (
		CLK	=> CLK,
        RST => RST,

		UART_TXD => open,
		UART_RXD  => '1',

        LED_OUT => led_out_s,

        SCLK_OUT => SCLK_OUT_s,
        SS_OUT=> SS_OUT_s,
        MOSI_OUT=> MOSI_OUT_s,
        MISO_IN=> MISO_IN_s

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
