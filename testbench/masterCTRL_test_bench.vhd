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

entity masterCTRLTB is
end masterCTRLTB;

architecture FULL of masterCTRLTB is

	signal CLK           	: std_logic := '0';
	signal RST           	: std_logic := '0';
	signal DATA_S		 	: std_logic := '0';
	signal DATA_OUT_S		: std_logic_vector(1 downto 0) := "11";
	signal COMMAND_S	 	: std_logic_vector(7 downto 0) := "00000000";

	signal Busy_s	 	 	: std_logic := '0';

	signal CONV_ENB_S    	:std_logic;
	signal CONV_CH_SEL_S 	:std_logic_vector(2 downto 0);
	signal DATA_VALID_S	 	:std_logic;
	signal ADC_CH_ADDRESS_S	:std_logic_vector(2 downto 0);
	signal ADC_DATAOUT_S	:std_logic_vector(11 downto 0);

	signal SCLKC_S	 		:std_logic;
	signal SS_S	 			:std_logic;
	signal MOSI_S	 		:std_logic;
	signal MISO_S 	 		:std_logic := '1';

    constant clk_period  : time := 20 ns;
	constant uart_period : time := 8680.56 ns;
	constant data_value  : std_logic_vector(7 downto 0) := "10100111";
	constant data_value2 : std_logic_vector(7 downto 0) := "00110110";

	type state_type_tb is (Reset, Running, State1, State2, State3);
	signal state : state_type_tb;


begin

	utt: entity work.masterCTRL
	generic map (
	    CLK_DIV   => 100  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)
	port map (
		clk	=> CLK,
		data_in => DATA_S,
		reset  => RST,
		enb_adc_conv => CONV_ENB_S,
		ch_adc_conv => CONV_CH_SEL_S,
		busy => Busy_s,
		data_out => DATA_OUT_S
	);


	utt_ad: entity work.adc_serial_control
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


	test_states : process
	begin
		RST <= '1';
		state <= Reset;
		wait for 100 ns;
		RST <= '0';
		state <= Running;

		-- Change State
		wait for 150 us;
		wait until rising_edge(CLK);
		DATA_S <= '1';
		wait until rising_edge(CLK);
		DATA_S <= '0';
		state <= State1;

		-- Change State
		wait for 950 us;
		wait until rising_edge(CLK);
		DATA_S <= '1';
		wait until rising_edge(CLK);
		DATA_S <= '0';
		state <= State1;

		-- Change State
		wait for 950 us;
		wait until rising_edge(CLK);
		DATA_S <= '1';
		wait until rising_edge(CLK);
		DATA_S <= '0';

		-- Change State
		wait for 950 us;
		wait until rising_edge(CLK);
		DATA_S <= '1';
		wait until rising_edge(CLK);
		DATA_S <= '0';

		-- Change State
		wait for 950 us;
		wait until rising_edge(CLK);
		DATA_S <= '1';
		wait until rising_edge(CLK);
		DATA_S <= '0';

		wait;

	end process;


end FULL;
