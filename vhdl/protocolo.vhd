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
    -- RX da UART
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
    data_bus_in  		: out	std_logic_vector(15 downto 0);
    data_bus_out 		: out	std_logic_vector(15 downto 0);

	----------------------------------------------------------------------------
    -- Data bus Controll
	address_bus_out		: out	std_logic_vector(15 downto 0);
	command_bus_out		: out	std_logic_vector(7 downto 0);

	----------------------------------------------------------------------------
	-- Controll Bus Signals
    chip_select			: out	std_logic_vector(15 downto 0);
    enable_out			: out	std_logic;
    enable_in			: in	std_logic;
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

	signal strobe		: std_logic_vector(3 downto 0);

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
					state <= rx_address_0;
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

	-- Proc para Receber e Registrar as informações
	reg_proc : process (CLK, RST)
	begin
		if RST = '1' then

			rSTART <= (others => '0');
			rADDRESS <= (others => '0');
			rCOMMAND <= (others => '0');
			rSTOP <= (others => '0');

		elsif (rising_edge(clk)) then
			if (data_en_in = '1') then
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
			end if;
		end if;
	end process;

	-- Proc para Controlar os sinais do Carramento
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
						rChipSelect <= (others => '1');
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
			command_bus_out <= (others => '0');
			chip_select		<= (others => '0');

		elsif (rising_edge(clk)) then
			case state is
				when Idle =>
					address_bus_out <= (others => '1');
					command_bus_out <= (others => '1');
					chip_select		<= (others => '1');
					data_bus_out 	<= (others => '1');

				when rx_stop=>
					address_bus_out <= rADDRESS;
					command_bus_out <= rCOMMAND;
					chip_select		<= rChipSelect;
					data_bus_out 	<= DATA_RAM_REG(0) & DATA_RAM_REG(1);

				when others =>
					address_bus_out <= (others => '1');
					command_bus_out <= (others => '1');
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

end rtl;
