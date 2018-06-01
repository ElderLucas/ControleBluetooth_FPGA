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

entity PROTOCOLO_TB is
end PROTOCOLO_TB;

architecture FULL of PROTOCOLO_TB is

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

  constant clk_period  : time := 20 ns;
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

    -- TX UART
    uart_rx: entity work.UART
      generic map (
          CLK_FREQ    => 50e6,
          BAUD_RATE   => 115200,
          PARITY_BIT  => "none"
      )
      port map (
          CLK         => CLK,
          RST         => RST,
          -- UART INTERFACE
          UART_TXD    => open,
          UART_RXD    => tx_uart,
          -- USER DATA INPUT INTERFACE
          DATA_OUT    => sdata,
          DATA_VLD    => data_vld,
          FRAME_ERROR => frame_error,
          -- USER DATA OUTPUT INTERFACE
          DATA_IN     => data_in,
          DATA_SEND   => data_send,
          BUSY        => busy
      );

    -- PROTOCOLO BLOCK
    protocolo_rx: entity work.PROTOCOLO
      generic map (
          CLK_DIV    => 100
      )
      port map (
          CLK           => CLK,
          RST           => RST,
          -- UART INTERFACE
          data_en_in    => data_vld, --sdata_vld,
          data_in 	    => data_in, --sdata,

          -- Barramento de dados interno
          data_bus_in   => sdata_bus_in,
          data_bus_out  => sdata_bus_out,

          -- Data bus Controll
          data_bus_cs   => sdata_bus_cs,
          data_bus_en_i => sdata_bus_en_i,
          data_bus_en_o => sdata_bus_en_o,
          data_bus_rw   => sdata_bus_rw
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


			-- ADDRESS 0
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000100";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);


	    -- ADDRESS 1
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000010";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);


	    -- COMMAND
	    wait until rising_edge(CLK);
	    data_send <= '1';
	    data_in <= "00000001";
	    wait until rising_edge(CLK);
	    data_send <= '0';
	    wait until rising_edge(CLK);
	    wait for 280 us;
	    wait until rising_edge(CLK);


	    -- DATA 0
	    wait until rising_edge(CLK);
	    data_send <= '1';
	    data_in <= "00000000";
	    wait until rising_edge(CLK);
	    data_send <= '0';
	    wait until rising_edge(CLK);
	    wait for 280 us;
	    wait until rising_edge(CLK);

			-- DATA 1
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000001";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);

			-- DATA 2
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= "00000010";
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);

			-- DATA 3
	    wait until rising_edge(CLK);
	    data_send <= '1';
	    data_in <= "00000011";
	    wait until rising_edge(CLK);
	    data_send <= '0';
	    wait until rising_edge(CLK);
	    wait for 280 us;
	    wait until rising_edge(CLK);

			-- DATA 4
	    wait until rising_edge(CLK);
	    data_send <= '1';
	    data_in <= "00000100";
	    wait until rising_edge(CLK);
	    data_send <= '0';
	    wait until rising_edge(CLK);
	    wait for 280 us;
	    wait until rising_edge(CLK);


			-- DATA 5
	    wait until rising_edge(CLK);
	    data_send <= '1';
	    data_in <= "00000101";
	    wait until rising_edge(CLK);
	    data_send <= '0';
	    wait until rising_edge(CLK);
	    wait for 280 us;
	    wait until rising_edge(CLK);

			-- DATA 6
	    wait until rising_edge(CLK);
	    data_send <= '1';
	    data_in <= "00000110";
	    wait until rising_edge(CLK);
	    data_send <= '0';
	    wait until rising_edge(CLK);
	    wait for 280 us;
	    wait until rising_edge(CLK);

			-- DATA 7
	    wait until rising_edge(CLK);
	    data_send <= '1';
	    data_in <= "00000111";
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

			wait for 500 us;

		end loop;

		wait;

	end process;

end FULL;
