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

	-- BANCO DE REGISTROS DO Módulo Master
	type RAM is array (0 to 31) of std_logic_vector(7 downto 0);
	signal CONFIG_WORD : RAM;

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

	-- Topo do projeto
	utt: entity work.topo
	generic map (
		CLK_FREQ    => 50e6,
		BAUD_RATE   => 115200,
		PARITY_BIT  => "none"
	)
	port map (

		------------------------------------------------------------------------
		-- Sinais Vitais do bloco
		------------------------------------------------------------------------
		CLK	=> CLK,
		RST => RST,
		------------------------------------------------------------------------
		-- Entrada e saída de UART
		------------------------------------------------------------------------
		UART_TXD => open,
		UART_RXD  => tx_uart,

		------------------------------------------------------------------------
		-- Saída de Led para Forçar a saída
		------------------------------------------------------------------------
		LED_OUT => led_out_s,

		------------------------------------------------------------------------
		--Interface com o ADC'
		------------------------------------------------------------------------
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


		for I in 0 to 1 loop

			if I = 0 then
				-- BYTE 0 - START FRAME
				CONFIG_WORD(0) <= "10101010"; --0xAA

				CONFIG_WORD(1) <= "00000000"; 	-- BYTE 1 - BLOCK ADDRESS LSW
				CONFIG_WORD(2) <= "00000000"; 	-- BYTE 2 - BLOCK ADDRESS MSW

				CONFIG_WORD(3) <= "00000000"; 	-- BYTE 3 - COMMAND - CRUD

				CONFIG_WORD(4) <= "00000000"; 	-- BYTE 4 - REGISTER ADDRESS MSB
				CONFIG_WORD(5) <= "00000000"; 	-- BYTE 5- REGISTER ADDRESS LSB

				CONFIG_WORD(6) <= "11001111"; 	-- BYTE 6 - DATA MSB
				CONFIG_WORD(7) <= "11001111"; 	-- BYTE 7 - DATA LSB

				CONFIG_WORD(8) <= "10101010"; 	-- BYTE 8 - RESERVADO
				CONFIG_WORD(9) <= "10101010"; 	-- BYTE 9 - RESERVADO
				CONFIG_WORD(10) <= "10101010";	-- BYTE 10 - RESERVADO
				CONFIG_WORD(11) <= "10101010";	-- BYTE 11 - RESERVADO

				CONFIG_WORD(12) <= "10101010";  -- STOP WORD

			elsif I = 1 then
				-- BYTE 0 - START FRAME
				CONFIG_WORD(0) <= "10101010"; --0xAA

				CONFIG_WORD(1) <= "00000000"; 	-- BYTE 1 - BLOCK ADDRESS LSW
				CONFIG_WORD(2) <= "00000000"; 	-- BYTE 2 - BLOCK ADDRESS MSW

				CONFIG_WORD(3) <= "00000000"; 	-- BYTE 3 - COMMAND - CRUD

				CONFIG_WORD(4) <= "00000000"; 	-- BYTE 4 - REGISTER ADDRESS MSB
				CONFIG_WORD(5) <= "00000000"; 	-- BYTE 5- REGISTER ADDRESS LSB

				CONFIG_WORD(6) <= "00000000"; 	-- BYTE 6 - DATA MSB
				CONFIG_WORD(7) <= "00000000"; 	-- BYTE 7 - DATA LSB

				CONFIG_WORD(8) <= "10101010"; 	-- BYTE 8 - RESERVADO
				CONFIG_WORD(9) <= "10101010"; 	-- BYTE 9 - RESERVADO
				CONFIG_WORD(10) <= "10101010";	-- BYTE 10 - RESERVADO
				CONFIG_WORD(11) <= "10101010";	-- BYTE 11 - RESERVADO

				CONFIG_WORD(12) <= "10101010";  -- STOP WORD

			end if;

			--------------------------------------------------------------------
			-- BYTE 0 - START FRAME
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= CONFIG_WORD(0);
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);

			--------------------------------------------------------------------
			-- BYTE 1 - BLOCK ADDRESS LSW
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= CONFIG_WORD(1);
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);

		    -- BYTE 2 - BLOCK ADDRESS MSW
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= CONFIG_WORD(2);
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);

			--------------------------------------------------------------------
		    -- BYTE 3 - COMMAND - CRUD
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(3); --CRUD WRITE REG
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);

			--------------------------------------------------------------------
		    -- BYTE 4 - REGISTER ADDRESS MSB
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(4);
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- BYTE 5- REGISTER ADDRESS LSB
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= CONFIG_WORD(5);
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);

			--------------------------------------------------------------------
		    -- BYTE 6 - DATA MSB
			wait until rising_edge(CLK);
			data_send <= '1';
			data_in <= CONFIG_WORD(6);
			wait until rising_edge(CLK);
			data_send <= '0';
			wait until rising_edge(CLK);
			wait for 280 us;
			wait until rising_edge(CLK);
			-- BYTE 7 - DATA LSB
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(7);
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);

			--------------------------------------------------------------------
		    -- BYTE 8 - RESERVADO
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(8);
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);
			-- BYTE 9 - RESERVADO
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(9);
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);


			--------------------------------------------------------------------
		    -- BYTE 10 - RESERVADO
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(10);
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);

			-- BYTE 11 - RESERVADO
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(11);
		    wait until rising_edge(CLK);
		    data_send <= '0';
		    wait until rising_edge(CLK);
		    wait for 280 us;
		    wait until rising_edge(CLK);


			-- STOP WORD
		    wait until rising_edge(CLK);
		    data_send <= '1';
		    data_in <= CONFIG_WORD(12);
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
