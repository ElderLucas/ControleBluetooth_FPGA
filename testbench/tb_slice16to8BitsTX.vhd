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

entity SLICE_TB is
end SLICE_TB;

architecture FULL of SLICE_TB is

	signal CLK           : std_logic := '0';
	signal RST           : std_logic := '0';
	signal timer_1seg_s  : std_logic := '0';
	constant clk_period  : time := 20 ns;

    signal EN_DATA_s     : std_logic := '0';
    signal DATA_OUT_s    : std_logic_vector(7 downto 0);  -- ADC converted channel
    signal EN_DATA_OUT_s : std_logic := '0';
    signal READ_BUSY_s   : std_logic := '0';

    signal DATA_TX_s    : std_logic_vector(15 downto 0);  -- ADC converted channel

begin

	utt: entity work.slice16to8bitsTX
	generic map (
	    CLK_FREQ   => 50e6  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)
	port map (
        -- Sinais Vitais
        CLK	=> CLK,
        RST  => RST,
        -- 16 Bits input
        DATA_IN => DATA_TX_s,
        EN_DATA_IN => EN_DATA_s,
        -- 8 Bits output
        DATA_OUT    => DATA_OUT_s,
        EN_DATA_OUT => EN_DATA_OUT_s,
        -- Read UART Status
        READ_BUSY   => READ_BUSY_s
	);

	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;

    main_proc : process
	begin
        RST <= '1';
        DATA_TX_s <= X"0000";
		wait for 100 ns;
		RST <= '0';
        READ_BUSY_s <= '1';
        --------- TX
        wait for 300 us;
        DATA_TX_s <= X"AABB";
		wait until rising_edge(CLK);
		EN_DATA_s <= '1'; -- start bit
        wait until rising_edge(CLK);
        EN_DATA_s <= '0'; -- start bit

		wait for 150 us;
        READ_BUSY_s <= '1';
		wait for 250 us;
        READ_BUSY_s <= '0';

        wait for 25 ns;
        READ_BUSY_s <= '1';
        wait for 150 us;
        READ_BUSY_s <= '0';


        --------- TX 2
        wait for 300 us;
        DATA_TX_s <= X"5544";
        wait until rising_edge(CLK);
        EN_DATA_s <= '1'; -- start bit
        wait until rising_edge(CLK);
        EN_DATA_s <= '0'; -- start bit

        wait for 150 us;
        READ_BUSY_s <= '1';
        wait for 150 us;
        READ_BUSY_s <= '0';

        wait for 150 us;
        READ_BUSY_s <= '1';
        wait for 150 us;
        READ_BUSY_s <= '0';

		wait;

	end process;


end FULL;
