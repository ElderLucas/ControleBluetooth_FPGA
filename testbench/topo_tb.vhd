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

	signal CLK           : std_logic := '0';
	signal RST           : std_logic := '0';
	signal led_out_s 	 : std_logic_vector(7 downto 0);
	signal SCLK_OUT_s    : std_logic := '0';
	signal SS_OUT_s      : std_logic := '0';
	signal MOSI_OUT_s    : std_logic := '0';
	signal MISO_IN_s	 : std_logic := '0';
	constant clk_period  : time := 20 ns;
	signal tx_uart       : std_logic;
	signal rx_uart       : std_logic := '1';
	signal data_vld      : std_logic;
	signal data_out      : std_logic_vector(7 downto 0);
	signal frame_error   : std_logic;
	signal data_send     : std_logic;
	signal busy          : std_logic;
	signal data_in       : std_logic_vector(7 downto 0);
	constant uart_period : time := 8680.56 ns;
	constant data_value  : std_logic_vector(7 downto 0) := "10100111";
	constant data_value2 : std_logic_vector(7 downto 0) := "00110110";
	signal sdata_vld      : std_logic := '1';
	signal sdata_in       : std_logic_vector(7 downto 0);
	signal sdata          : std_logic_vector(7 downto 0);
	signal sdata_bus_in   : std_logic_vector(15 downto 0);
	signal sdata_bus_out  : std_logic_vector(15 downto 0);
	signal sdata_bus_cs   : std_logic_vector(7 downto 0);
	signal sdata_bus_en_i : std_logic := '1';
	signal sdata_bus_en_o : std_logic := '1';
	signal sdata_bus_rw   : std_logic := '1';

begin

	-- TX UART
	uart_tx: entity work.UART
	generic map (
		CLK_FREQ    => 50e6,
		BAUD_RATE   => 115200,
		PARITY_BIT  => "none"
	)
	port map (
		CLK         => CLK,
		RST         => RST,
		-- UART INTERFACE
		UART_TXD    => tx_uart,
		UART_RXD    => rx_uart,
		-- USER DATA INPUT INTERFACE
		DATA_OUT    => open,
		DATA_VLD    => open,
		FRAME_ERROR => open,
		-- USER DATA OUTPUT INTERFACE
		DATA_IN     => data_in,
		DATA_SEND   => data_send,
		BUSY        => busy
	);

	utt: entity work.topo
	generic map (
		CLK_FREQ    => 50e6,
		BAUD_RATE   => 115200,
		PARITY_BIT  => "none"
	)
	port map (
		CLK	=> CLK,
		RST => RST,

		-- Entrada e saída de UART
		UART_TXD => open,
		UART_RXD  => tx_uart,

		-- Saída de Led para Forçar a saída
		LED_OUT => led_out_s,
		--Interface com o ADC'
		SCLK_OUT => SCLK_OUT_s,
		SS_OUT=> SS_OUT_s,
		MOSI_OUT=> MOSI_OUT_s,
		MISO_IN=> '1'
	);


		--
	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;


	test_tx_uart : process
	begin
		-- RESET SIGNAL
		data_send <= '0';
		RST <= '1';
		wait for 100 ns;
	    RST <= '0';

		for I in 0 to 3 loop
			-- START FRAME
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "10101010";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);
			-- ADDRESS 0 LSW
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000001";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);
		    -- ADDRESS 1 MSW
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000000";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);
		    -- COMMAND
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "00000011";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
		    -- DATA 0
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "00000100";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- DATA 1
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000101";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);
			-- DATA 2
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000110";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);
			-- DATA 3
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "00000111";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- DATA 4
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "00001000";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- DATA 5
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "00001001";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- DATA 6
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "00001010";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- DATA 7
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "00001011";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- STOP WORD
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= "01010101";
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);

			-- Delay Entre cada Pack de Informação
			wait for 1 ms;
		end loop;

		wait;

	end process;



end FULL;
