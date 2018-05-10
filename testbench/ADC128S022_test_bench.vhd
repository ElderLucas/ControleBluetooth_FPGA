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

entity ADC128S022_TB is
end ADC128S022_TB;

architecture FULL of ADC128S022_TB is

	signal CLK           : std_logic := '0';
	signal RST           : std_logic := '0';
	signal tx_uart       : std_logic;
	signal rx_uart       : std_logic := '1';
	signal data_vld      : std_logic;
	signal data_out      : std_logic_vector(7 downto 0);
	signal frame_error   : std_logic;
	signal data_send     : std_logic;
	signal busy          : std_logic;
	signal data_in       : std_logic_vector(7 downto 0);

	signal CONV_ENB_S    	:std_logic;
	signal CONV_CH_SEL_S 	:std_logic_vector(2 downto 0);
	signal DATA_VALID_S	 	:std_logic;
	signal ADC_CH_ADDRESS_S	:std_logic_vector(2 downto 0);
	signal ADC_DATAOUT_S	:std_logic_vector(11 downto 0);

	signal SCLKC_S	 		:std_logic;
	signal SS_S	 			:std_logic;
	signal MOSI_S	 		:std_logic;
	signal MISO_S 	 		:std_logic;

    constant clk_period  : time := 20 ns;
	constant uart_period : time := 8680.56 ns;
	constant data_value  : std_logic_vector(7 downto 0) := "10100111";
	constant data_value2 : std_logic_vector(7 downto 0) := "00110110";

begin

	utt: entity work.adc_serial_control
	generic map (
	    CLK_DIV   => 100  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)
	port map (
	    i_clk	=> CLK,
	    i_rstb  => RST,
	    i_conv_ena => CONV_ENB_S, 			-- enable ADC convesion
	    i_adc_ch => CONV_CH_SEL_S,			-- ADC channel 0-7
	    o_adc_data_valid => DATA_VALID_S, 	-- conversion valid pulse
	    o_adc_ch => ADC_CH_ADDRESS_S,  		-- ADC converted channel
	    o_adc_data => ADC_DATAOUT_S,        -- adc parallel data
	    -- ADC serial interface
	    o_sclk => SCLKC_S,
	    o_ss => SS_S,
	    o_mosi =>MOSI_S,
	    i_miso => MISO_S
	);


	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;


	test_enb_adc : process
	begin
		RST <= '0';
		CONV_ENB_S <= '0';
		CONV_CH_SEL_S <= "000";
		wait for 100 ns;
    	RST <= '1';
		CONV_CH_SEL_S <= "001";

		wait until rising_edge(CLK);

		rx_uart <= '0'; -- start bit
		CONV_ENB_S <= '1';

		wait for uart_period;

		for i in 0 to (data_value'LENGTH-1) loop
			rx_uart <= data_value(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to (data_value2'LENGTH-1) loop
			rx_uart <= data_value2(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		wait;

	end process;


end FULL;
