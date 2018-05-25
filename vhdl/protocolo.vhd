-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity protocolo is
	generic(
	    CLK_DIV : integer := 100 );  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	port(
    -- Sinais Vitais ao Bloco
		CLK		 		        : in	std_logic;
    RST               : in	std_logic;

    --Dados vindos do bloco de RX da UART
    data_en_in        : in	std_logic;
    data_in 	        : in	std_logic_vector(7 downto 0);

    -- Barramento de dados interno
    data_bus_in       : out	std_logic_vector(15 downto 0);
    data_bus_out      : out	std_logic_vector(15 downto 0);

    -- Data bus Controll
    data_bus_cs       : out	std_logic_vector(7 downto 0);
    data_bus_en_i     : out	std_logic;
    data_bus_en_o     : out	std_logic;
    data_bus_rw       : out	std_logic
);

end entity;

architecture rtl of protocolo is

	-- Controle de Teste do Módulo Alimentação
	type state_type_master is (Idle, rx_address, rxcommand, rx_data, rx_stop);

	-- Register to hold the current state
	signal state   : state_type_master;

begin
	--Logic to advance to the next state
	controle_ad_proc : process (CLK, RST)
	begin
		if RST = '1' then
			state <= Idle;

		elsif (rising_edge(clk)) then
			case state is

        -- IDLE State
				when Idle=>
					if data_en_in = '1' then
						state <= rx_address;
					else
						state <= Idle;
					end if;

        -- RECEBE O ENDEREÇO
				when rx_address=>
					if data_en_in = '1' then
						state <= rxcommand;
					else
						state <= rx_address;
					end if;

        -- RECEBE O COMANDO
  			when rxcommand=>
  				if data_en_in = '1' then
  					state <= rx_data;
  				else
  					state <= rxcommand;
  				end if;

        -- RECEBE O DADO
				when rx_data=>
					if data_en_in = '1' then
						state <= rx_stop;
					else
						state <= rx_data;
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

end rtl;
