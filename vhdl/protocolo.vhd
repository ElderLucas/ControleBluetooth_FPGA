-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity protocolo is
	generic(
	    CLK_DIV : integer := 100 );  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	port(
	----------------------------------------------------------------------------
    -- Sinais Vitais ao Bloco
	CLK 		 		: in	std_logic;
    RST			 		: in	std_logic;

	----------------------------------------------------------------------------
	-- Busy Signal FPGA
	fpga_busy_out		: out	std_logic;

	----------------------------------------------------------------------------
	-- Sinal de Busy do módulo TX da UART
	uart_tx_busy_in		: in	std_logic;

	----------------------------------------------------------------------------
	-- Entrada de dados no Bloco de Protocolo
	----------------------------------------------------------------------------
    -- Dados vindos do bloco de RX da UART
  	data_en_in	 		: in	std_logic;
    data_in 	 		: in	std_logic_vector(7 downto 0);

	----------------------------------------------------------------------------
	-- Saída de dados no Bloco de Protocolo
	----------------------------------------------------------------------------
	-- TX da UART
	data_en_out	 		: out	std_logic;
	data_out 	 		: out	std_logic_vector(7 downto 0);

	----------------------------------------------------------------------------
    -- Barramento de dados interno da FPGA
	----------------------------------------------------------------------------
	-- Dados Vindos dos Blocos internos à FPGA
    data_bus_in  		: in	std_logic_vector(15 downto 0);
	enable_in			: in	std_logic;

	--
    data_bus_out 		: out	std_logic_vector(15 downto 0);
	enable_out			: out	std_logic;

	----------------------------------------------------------------------------
    -- Data bus Controll
	address_bus_out		: out	std_logic_vector(15 downto 0);
    chip_select			: out	std_logic_vector(15 downto 0);
    crud_out     		: out	std_logic_vector(3 downto 0) --CRUD : Create, Read, Update, Delete

);
end entity;

architecture rtl of protocolo is

	-- Controle de Teste do Módulo Alimentação
	type state_type_master is (
		Idle,
		rx_address_0,
		rx_address_1,
		rx_command,
		rx_data,
		rx_stop
	);

	-- Register to hold the current state
	signal state   : state_type_master;

	-- Registro de dados de entrada do blocos
	signal reg_data_in	: std_logic_vector(7 downto 0);

	-- Registro do sinal de Enable data in
	signal rdata_en_in	: std_logic := '0';

	-- Count Data RX
	signal count_rx_data : integer := 0;

	-- REG ADDRESS
	signal rSTART		: std_logic_vector(7 downto 0);
	signal rSTOP		: std_logic_vector(7 downto 0);
	signal rADDRESS		: std_logic_vector(15 downto 0);
	signal rCOMMAND		: std_logic_vector(7 downto 0);
	signal rChipSelect	: std_logic_vector(15 downto 0);

	type BYTE is array (7 downto 0) of std_logic;
	type RAM is array (0 to 31) of std_logic_vector(7 downto 0);

	signal A_BUS 		: BYTE;
	signal DATA_RAM_REG : RAM;

	signal strobe		 : std_logic_vector(3 downto 0);

	signal data_bus_in_s : std_logic_vector(15 downto 0);
	signal enable_in_s	 : std_logic;

	-- Count Time Out
	signal count_time_out : integer := 0;
	signal reset_time_out_tx : std_logic;
	signal time_out_tx : std_logic;


	signal tx_data_s 		: std_logic_vector(7 downto 0);
	signal tx_data_enable_s : std_logic_vector(3 downto 0);


	signal shift_reg_busy : std_logic_vector(3 downto 0);



	----------------------------------------------------------------------------
	-- Máquina de Estados para controlar o envio dos dados pela UART TX
	----------------------------------------------------------------------------
	-- Controle de Teste do Módulo Alimentação
	type state_type_tx_uart is (
		Idle,
		wait_uart_tx,
		start_byte,
		lsb,
		msb,
		stop_byte
	);

	-- Register to hold the current state
	signal state_tx_uart   : state_type_tx_uart;

	-- Controle de Teste do Módulo Alimentação

begin

	-- -------------------------------------------------------------------------
	-- PROCESSO PARA REGISTRO DO DATAREG
	-- -------------------------------------------------------------------------
	data_reg_proc : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (RST = '1') then
				reg_data_in <= (others => '0');
			else
				if data_en_in = '1' then
					reg_data_in <= data_in;
				end if;
			end if;
		end if;
	end process;

	-- -------------------------------------------------------------------------
	-- PROCESSO PARA REGISTRO DO SINAL DE ENABLE DATAREG
	-- -------------------------------------------------------------------------
	enb_data_reg_proc : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (RST = '1') then
				rdata_en_in <= '0';
			else
				if data_en_in = '1' then
					rdata_en_in <= data_en_in;
				else
					rdata_en_in <= '0';
				end if;
			end if;
		end if;
	end process;

	-- -------------------------------------------------------------------------
	--Logic to advance to the next state
	-- -------------------------------------------------------------------------
	state_machine_main_proc : process (CLK, RST)
	begin
		if RST = '1' then
			state <= Idle;

		elsif (rising_edge(clk)) then
			case state is
        	-- IDLE State
			when Idle=>
				if data_en_in = '1' then
					if(data_in = "10101010") then--0xAA
						state <= rx_address_0;
					end if;
				else
					state <= Idle;
				end if;
        	-- RECEBE O ENDEREÇO LSW - Palavra Menos Significante
			when rx_address_0 =>
				if data_en_in = '1' then
					state <= rx_address_1;
				else
					state <= rx_address_0;
				end if;
			-- RECEBE O ENDEREÇO MSW - Palavra Mais Significante
			when rx_address_1 =>
				if data_en_in = '1' then
					state <= rx_command;
				else
					state <= rx_address_1;
				end if;

        	-- RECEBE O COMANDO
  			when rx_command=>
  				if data_en_in = '1' then
  					state <= rx_data;
  				else
  					state <= rx_command;
  				end if;

        	-- RECEBE O DADO
			when rx_data=>
				if count_rx_data < 8 then
					state <= rx_data;
				else
					state <= rx_stop;
				end if;

        	-- RECEBE A PALAVRA DE FIM DE QUADRO
			when rx_stop=>
				if data_en_in = '1' then
					state <= Idle;
				else
					state <= rx_stop;
				end if;

			end case;
		end if;
	end process;


	--Logic to advance to the next state
	STM_COUNT_Data_UART2PROTOCOL_proc : process (CLK, RST)
	begin
		if RST = '1' then
			count_rx_data <= 0;
		elsif (rising_edge(clk)) then
			case state is
				-- IDLE State
				when Idle=>
					count_rx_data <= 0;
				-- RECEBE O ENDEREÇO LSW - Palavra Menos Significante
				when rx_address_0 =>
				-- RECEBE O ENDEREÇO MSW - Palavra Mais Significante
				when rx_address_1 =>
				-- RECEBE O COMANDO
				when rx_command=>
				-- RECEBE O DADO
				when rx_data=>
					if data_en_in = '1' then
						if count_rx_data <= 8 then
							count_rx_data <= count_rx_data + 1;
						else
							count_rx_data <= 0;
						end if;
					end if;
				-- RECEBE A PALAVRA DE FIM DE QUADRO
				when rx_stop=>
					count_rx_data <= 0;
			end case;
		end if;
	end process;

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	--
	-- Proc para receber as informações de Address, Comando e Dados
	-- vindos do Pacote serial.
	-- Todos os dados recebidos pela UART são disponibilizados no
	-- data_in juntamente com um Enable (1 ciclo de Clock)
	--
	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	DataPack_SerialDecode_Reg_proc : process (CLK, RST, state)
	begin
		if RST = '1' then
			rSTART <= (others => '0');
			rADDRESS <= (others => '0');
			rCOMMAND <= (others => '0');
			rSTOP <= (others => '0');
		elsif (rising_edge(clk)) then
			--if (data_en_in = '1') then
			case state is
				-- IDLE State
				when Idle=>
					rSTART <= data_in;
				-- RECEBE O ENDEREÇO LSW - Palavra Menos Significante
				when rx_address_0 =>
					rADDRESS(7 downto 0) <= data_in;
				-- RECEBE O ENDEREÇO MSW - Palavra Mais Significante
				when rx_address_1 =>
					rADDRESS(15 downto 8) <= data_in;
				-- RECEBE O COMANDO
				when rx_command=>
					rCOMMAND <= data_in;
				-- RECEBE O DADO
				when rx_data=>
					if count_rx_data < 8 then
						DATA_RAM_REG(count_rx_data) <= data_in;
					end if;
				-- RECEBE A PALAVRA DE FIM DE QUADRO
				when rx_stop=>
					rSTOP <= data_in;
			end case;
			--end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Proc para Controlar os sinais do Carramento
	----------------------------------------------------------------------------
	chipSelec_proc : process (CLK, RST)
	begin
		if RST = '1' then
			rChipSelect <= (others => '0');
		elsif (rising_edge(clk)) then
			case state is
				when Idle =>
					rChipSelect <= (others => '1');
				when rx_data=>
					if(rADDRESS = "0000000000000000")then
						rChipSelect <= "1111111111111110";
					elsif(rADDRESS = "0000000000000001")then
						rChipSelect <= "1111111111111101";
					elsif(rADDRESS = "0000000000000010")then
						rChipSelect <= "1111111111111011";
					elsif(rADDRESS = "0000000000000011")then
						rChipSelect <= "1111111111110111";
					elsif(rADDRESS = "0000000000000100")then
						rChipSelect <= "1111111111101111";
					elsif(rADDRESS = "0000000000000101")then
						rChipSelect <= "1111111111011111";
					else
						rChipSelect <= (others => 'X');
					end if;
				when others =>
					--rChipSelect <= (others => '1');
			end case;
		end if;
	end process;

	-- Proc para Controlar os sinais do Barramento
	busctrl_proc : process (CLK, RST)
	begin
		if RST = '1' then
			address_bus_out <= (others => '0');
			chip_select		<= (others => '0');

		elsif (rising_edge(clk)) then
			case state is
				when Idle =>
					address_bus_out <= (others => '1');
					chip_select		<= (others => '1');
					data_bus_out 	<= (others => '1');

				when rx_stop=>
					address_bus_out <= DATA_RAM_REG(0) & DATA_RAM_REG(1);
					chip_select		<= rChipSelect;
					data_bus_out 	<= DATA_RAM_REG(2) & DATA_RAM_REG(3);

				when others =>
					address_bus_out <= (others => '1');
					--chip_select		<= (others => '1');
					data_bus_out 	<= (others => '1');

			end case;
		end if;
	end process;

	-- Proc para Controlar os sinais do Barramento
	strobe_outenable_proc : process (CLK, RST)
	begin
		if RST = '1' then
			strobe <= (others => '0');
		elsif (rising_edge(clk)) then
			case state is
				when rx_data=>
					strobe <= "0001";
				when rx_stop=>
					strobe <= strobe(2 downto 0) & '0';
				when others =>
					strobe <= (others => '0');
			end case;
		end if;
	end process;

	enable_out <= strobe(1);
	crud_out <= rCOMMAND(3 downto 0);


	----------------------------------------------------------------------------
	--------------------------- TX DATA UART -----------------------------------
	--
	--	Processos para receber os dados dos blocos  e transmitir para UART
	--

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	-- Proc para registrar os dados de Data e Enable
	-- vindos dos Blocos da FPGA.
	-- Neste caso recebe os dados vindos do Master e transmite para
	-- UART TX
	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	process (CLK, RST)
	begin
		if RST = '1' then
			data_bus_in_s <= (others => '0');
			enable_in_s <= '0';
		elsif (rising_edge(clk)) then
			if enable_in = '1' then
				data_bus_in_s <= data_bus_in;
				enable_in_s <= enable_in;
			else
				enable_in_s <= '0';
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Proc Contagem do Time Out
	----------------------------------------------------------------------------
	process (CLK, RST)
	begin
		if RST = '1' then
			count_time_out <= 0;
			time_out_tx <= '0';
		elsif (rising_edge(clk)) then
			if reset_time_out_tx = '0' then
				if count_time_out < 100000 then
					count_time_out <= count_time_out + 1;
				else
					count_time_out <= 0;
					time_out_tx <= '1';
				end if;

			else
				count_time_out <= 0;
				time_out_tx <= '0';
			end if;
		end if;
	end process;

	-- -------------------------------------------------------------------------
	-- PROC para transmitir dados via interface UART
	-- -------------------------------------------------------------------------
	state_machine_uart_tx : process (CLK, RST)
	begin
		if RST = '1' then
			state_tx_uart <= Idle;
			reset_time_out_tx <= '0';

		elsif (rising_edge(clk)) then
			case state_tx_uart is
				when Idle=>
					if enable_in_s = '1' then
						state_tx_uart <= wait_uart_tx;
					end if;
					reset_time_out_tx <= '1';

				when wait_uart_tx =>
					if time_out_tx = '0' then
						if shift_reg_busy = "0000" then --UART Ocupada
							state_tx_uart <= start_byte;
							reset_time_out_tx <= '1';
						else --UART TX desocupada
							state_tx_uart <= wait_uart_tx;
							reset_time_out_tx <= '0';

						end if;
					else -- Contador de TimeOut estourou
						state_tx_uart <= Idle;
						--reset_time_out_tx <= '1';
					end if;

				when start_byte=>
					if time_out_tx = '0' then
						if shift_reg_busy = "1110" then --UART Ocupada
							state_tx_uart <= lsb;
							reset_time_out_tx <= '1';
						else --UART TX desocupada
							state_tx_uart <= start_byte;
							reset_time_out_tx <= '0';
						end if;
					else -- Contador de TimeOut estourou
						state_tx_uart <= Idle;
						reset_time_out_tx <= '1';
					end if;

				when lsb=>
					if time_out_tx = '0' then
						if shift_reg_busy = "1110" then --UART Ocupada
							state_tx_uart <= msb;
							reset_time_out_tx <= '1';
						else --UART TX desocupada
							state_tx_uart <= lsb;
							reset_time_out_tx <= '0';

						end if;
					else -- Contador de TimeOut estourou
						state_tx_uart <= Idle;
						reset_time_out_tx <= '1';
					end if;

				when msb=>
					if time_out_tx = '0' then
						if shift_reg_busy = "1110" then --UART Ocupada
							state_tx_uart <= stop_byte;
							reset_time_out_tx <= '1';
						else --UART TX desocupada
							state_tx_uart <= msb;
							reset_time_out_tx <= '0';
						end if;
					else -- Contador de TimeOut estourou
						state_tx_uart <= Idle;
						reset_time_out_tx <= '1';
					end if;

				when stop_byte=>
					if time_out_tx = '0' then
						if shift_reg_busy = "1110" then --UART Ocupada
							state_tx_uart <= Idle;
							reset_time_out_tx <= '1';
						else --UART TX desocupada
							state_tx_uart <= stop_byte;
							reset_time_out_tx <= '0';
						end if;
					else -- Contador de TimeOut estourou
						state_tx_uart <= Idle;
						reset_time_out_tx <= '1';
					end if;
			end case;
		end if;
	end process;

	observer_state_machine_uart_tx : process (RST, clk, state_tx_uart)
	begin
		if RST = '1' then
			data_en_out <= '0';
			data_out <= "11111111";
		elsif (rising_edge(clk)) then
			case state_tx_uart is
				when Idle=>
					tx_data_s <= (others => '0');
					tx_data_enable_s <= "0001";
					data_en_out <= '0';

				when wait_uart_tx =>
					--data_en_out <= '1';
					--data_out <= "10101010";

				when start_byte=>
					data_en_out <= '1';
					data_out <= "10101010";
				when lsb=>
					data_en_out <= '1';
					data_out <= data_bus_in_s(7 downto 0);
				when msb=>
					data_en_out <= '1';
					data_out <= data_bus_in_s(15 downto 8);
				when stop_byte=>
					data_en_out <= '1';
					data_out <= "01010101";
			end case;
		else
			--data_en_out <= '0';
		end if;
	end process;

	process (RST, clk)
	begin
		if RST = '1' then
			shift_reg_busy <= "0000";
		elsif (rising_edge(clk)) then
			shift_reg_busy <= shift_reg_busy(2 downto 0) & uart_tx_busy_in;
		end if;
	end process;

end rtl;
