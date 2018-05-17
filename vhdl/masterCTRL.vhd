-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity masterCTRL is
	generic(
	    CLK_DIV : integer := 100 );  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	port(
		clk		 		: in	std_logic;
		data_in	 		: in	std_logic;
		reset	 		: in	std_logic; --Reset Ativado em Nivel Lógico Alto
		enb_adc_conv 	: out	std_logic;
		ch_adc_conv 	: out	std_logic_vector(2 downto 0);
		busy	 		: out	std_logic;
		data_out 		: out	std_logic_vector(1 downto 0)
	);

end entity;

architecture rtl of masterCTRL is

	-- Build an enumerated type for the state machine
	type state_type is (s0, s1, s2, s3);

	-- Controle de Teste do Módulo Alimentação
	type state_type_master is (Idle, Teste, Comando, SucessoTeste, ErroTeste, convADC_Ch0, convADC_Ch1, convADC_Ch2);

	-- Register to hold the current state
	signal state   : state_type_master;

	-- Estados Relativos ao controne do
	signal state_master   : state_type_master;

	-- Erro simulado
	signal erro_s : std_logic := '0'; -- '0' Ok / '1' - Erro

begin
	-- Logic to advance to the next state
	process (clk, reset)
	begin
		if reset = '1' then
			state <= Idle;
		elsif (rising_edge(clk)) then
			case state is
				when Idle=>
					if data_in = '1' then
						state <= Teste;
					else
						state <= Idle;
					end if;
				when Teste=>
					if data_in = '1' then
						state <= convADC_Ch0;
					else
						state <= Teste;
					end if;

				-- ADC CH 0
				when convADC_Ch0=>
					if data_in = '1' then
						state <= convADC_Ch1;
					else
						state <= convADC_Ch0;
					end if;

				-- ADC CH 1
				when convADC_Ch1=>
					if data_in = '1' then
						state <= convADC_Ch2;
					else
						state <= convADC_Ch1;
					end if;

				-- ADC CH 2
				when convADC_Ch2=>
					if data_in = '1' then
						state <= Comando;
					else
						state <= convADC_Ch2;
					end if;

				when Comando=>
					if data_in = '1' and erro_s = '0' then
						state <= SucessoTeste;
					elsif data_in = '1' and erro_s = '1' then
						state <= ErroTeste;
					else
						state <= Comando;
					end if;

				when SucessoTeste =>
					if data_in = '1' then
						state <= Idle;
					else
						state <= SucessoTeste;
					end if;

				when ErroTeste =>
					if data_in = '0' then
						state <= ErroTeste;
					else
						state <= ErroTeste;
					end if;

			end case;
		end if;
	end process;

	-- Output depends solely on the current state
	process (state)
	begin
		case state is
			when Idle =>
				data_out <= "00";
				busy <= '0';
				--ADC Controle
				enb_adc_conv <= '0';
				ch_adc_conv <= "000";

			when Teste =>
				data_out <= "01";
				busy <= '1';
				--ADC Controle
				enb_adc_conv <= '0';

			when Comando =>
				data_out <= "10";
				busy <= '1';
				--ADC Controle
				enb_adc_conv <= '0';

			when convADC_Ch0 =>
				--ADC Controle
				enb_adc_conv <= '1';
				ch_adc_conv <= "000";

			when convADC_Ch1 =>
				--ADC Controle
				enb_adc_conv <= '1';
				ch_adc_conv <= "001";

			when convADC_Ch2 =>
				--ADC Controle
				enb_adc_conv <= '1';
				ch_adc_conv <= "010";

			when SucessoTeste =>
				data_out <= "11";
				busy <= '1';
				--ADC Controle
				enb_adc_conv <= '0';

			when ErroTeste =>
				--ADC Controle
				enb_adc_conv <= '0';
				data_out <= "00";
				busy <= '1';

		end case;
	end process;

end rtl;
