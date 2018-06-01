-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity masterCTRL is
	generic(
	    CLK_DIV : integer := 100 );  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	port(
		------------------------------------------------------------------------
		-- Sinais Vitais ao Bloco
		CLK 		 		: in	std_logic;
		RST			 		: in	std_logic;
		------------------------------------------------------------------------
	    -- SLAVE
		------------------------------------------------------------------------
	    data_bus_in  		: in	std_logic_vector(15 downto 0);
		enable_in			: in	std_logic;

		data_bus_out 		: out	std_logic_vector(15 downto 0);
		enable_out			: in	std_logic;

		------------------------------------------------------------------------
	    -- Data bus Controll
		address_bus_in		: in	std_logic_vector(15 downto 0);
		command_bus_in		: in	std_logic_vector(7 downto 0);
		------------------------------------------------------------------------
		-- Controll Bus Signals
	    chip_select			: in	std_logic_vector(15 downto 0);
	    crud_in     		: in	std_logic_vector(3 downto 0) --CRUD : Create, Read, Update, Delete
		------------------------------------------------------------------------
		-- ADC Controll
		------------------------------------------------------------------------
		adc_data_in	 		: in	std_logic;
		enb_adc_conv 		: out	std_logic;
		ch_adc_conv 		: out	std_logic_vector(2 downto 0);
		------------------------------------------------------------------------
		-- Status do Bloco
		------------------------------------------------------------------------
		busy	 			: out	std_logic
	);
end entity;

architecture rtl of masterCTRL is

	-- Build an enumerated type for the state machine
	type state_type is (s0, s1, s2, s3);

	-- Controle de Teste do Módulo Alimentação
	type state_type_master is (Idle, convADC_Ch0, convADC_Ch1, convADC_Ch2);

	-- Register to hold the current state
	signal state   : state_type_master;

	-- Estados Relativos ao controne do
	signal state_master   : state_type_master;

	-- Erro simulado
	signal erro_s : std_logic := '0'; -- '0' Ok / '1' - Erro

	-- enb_data_in
	signal enb_data_in : std_logic := '0';

begin

	enb_data_in <= data_in;

	-- Logic to advance to the next state
	controle_ad_proc : process (clk, reset)
	begin
		if reset = '1' then
			state <= Idle;
		elsif (rising_edge(clk)) then
			case state is
				when Idle=>
					if enb_data_in = '1' then
						state <= convADC_Ch0;
					else
						state <= Idle;
					end if;

				-- ADC CH 0
				when convADC_Ch0=>
					if enb_data_in = '1' then
						state <= convADC_Ch1;
					else
						state <= convADC_Ch0;
					end if;

				-- ADC CH 1
				when convADC_Ch1=>
					if enb_data_in = '1' then
						state <= convADC_Ch2;
					else
						state <= convADC_Ch1;
					end if;

				-- ADC CH 2
				when convADC_Ch2=>
					if enb_data_in = '1' then
						state <= convADC_Ch0;
					else
						state <= convADC_Ch2;
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

		end case;
	end process;




	-- -------------------------------------------------------------------------
	-- PROCESSO PARA REGISTRO DO DATAREG
	-- -------------------------------------------------------------------------
	data_reg_proc : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (RST = '1') then
				data_bus_out <= (others => '0');
			else
				if enable_in = '1' then
					data_bus_out <= data_bus_in;
				end if;
			end if;
		end if;
	end process;


end rtl;
