-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity gpio_CTRL is
	generic(
	    CLK_DIV : integer := 100 );  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	port(
		CLK 		 		: in	std_logic;
		RST			 		: in	std_logic;
		-- Entrada de dados
		data_in  			: in	std_logic_vector(15 downto 0);
		address_in			: in	std_logic_vector(15 downto 0);
		crud_in     		: in	std_logic_vector(3 downto 0);
		enable_data_in		: in	std_logic;
		chip_select			: in	std_logic;
		-- Saida de dados
		data_bus_out 		: out	std_logic_vector(15 downto 0);
		enable_data_out		: out	std_logic;

		-- Enable data in
		gpio_out		         : out 	std_logic_vector(7 downto 0);

		-- Sinaliza que está ocupado
		busy	 			: out	std_logic
	);
end entity;

architecture rtl of gpio_CTRL is

	-- Erro simulado
	signal erro_s 			: std_logic := '0'; -- '0' Ok / '1' - Erro
	-- enb_data_in
	signal enb_data_in 		: std_logic := '0';
	-- Write Signals
	signal write_data_ram 	: std_logic := '0';

	-- Register Read Signals
	signal r_address_bus_in	: std_logic_vector(15 downto 0);
	signal r_data_bus_in	: std_logic_vector(15 downto 0);
	signal read_data_ram	: std_logic;
	signal r_chip_select	: std_logic;
	-- Register Read Signals
	signal r_read_data		: std_logic_vector(15 downto 0);
	-- Enable Data Out
	signal shift_enb_data_out : std_logic_vector(3 downto 0) := "0000";
	signal r_enb_data_out : std_logic;

	----------------------------------------------------------------------------
	-- Palavras de habilitação dos Enables
	signal reg_enable_test	: std_logic_vector(15 downto 0);
	----------------------------------------------------------------------------
	-- Máquina de estados das operações dos blocos de registros do Módulo
	type state_reg_type is (Idle,
							DecodeAddress,
							DecodeCommand,
							WriteReg,
							ReadReg,
							UpdateReg,
							DeleteReg,
							WaitingProcess,
							TXData,
							EndProcess);

	-- Criando a máquina de estados para controle das operações dos registros
	signal RegState : state_reg_type;

	-- BANCO DE REGISTROS DO Módulo Master
	type RAM is array (0 to 31) of std_logic_vector(15 downto 0);

	signal RW_REGISTER_BANK : RAM;

	-- Contador de Tempo
	constant COUNTER_ADC_TIMER  : integer := 5000;--500000;
    signal timer_adc_cnt        : integer := 0;
	signal TIMER_1SEG			: std_logic := '0';
	signal start_test			: std_logic := '0';
	signal reg_led				: std_logic_vector(15 downto 0);

begin

	----------------------------------------------------------------------------
	-- INICIO DOS PROCESSOS DE CONTROLE INTERFACE COM O BARRAMENTO INTERNO
	----------------------------------------------------------------------------
	-- *** O barramento interno é o barramento de comunicação entre todos
	--     os blocos internos.
	----------------------------------------------------------------------------

	----------------------------------------------------------------------------
	-- Máquina de estados dos registros dos Blocos
	----------------------------------------------------------------------------
	StateMachine_Register_RW : process (clk, RST)
	begin
		if RST = '1' then
			RegState <= Idle;
		elsif (rising_edge(clk)) then
			case RegState is
				when Idle=>
					if enable_data_in = '1' and chip_select = '0' then
						RegState <= DecodeAddress;
					end if;

				when DecodeAddress =>
					RegState <= DecodeCommand;

				when DecodeCommand =>
					if crud_in = "0000" then 	--WriteReg
						RegState <= WriteReg;
					elsif crud_in = "0001" then --ReadReg
						RegState <= ReadReg;
					elsif crud_in = "0010" then --UpdateReg
						RegState <= UpdateReg;
					elsif crud_in = "0011" then --DeleteReg
						RegState <= DeleteReg;
					end if;

				when WriteReg =>
					RegState <= EndProcess;

				when ReadReg =>
					RegState <= TXData;

				when UpdateReg =>
					RegState <= EndProcess;

				when DeleteReg =>
					RegState <= EndProcess;

				when TXData =>
					RegState <= EndProcess;

				when WaitingProcess =>
					RegState <= Idle;

				when EndProcess =>
					RegState <= Idle;
			end case;
		end if;
	end process;

	observer_StateMachine_Register_WRITE_proc : process (clk, RST, RegState) -- State Machine Write Reg Proc
	begin
		if RST = '1' then
			write_data_ram <= '0';
			r_data_bus_in <= (others => '0');

		elsif (rising_edge(clk)) then
				case RegState is
					when Idle=>
						write_data_ram <= '0';
					when DecodeAddress =>
						r_address_bus_in <= address_in;
						r_data_bus_in <= data_in;
					when WriteReg =>
						write_data_ram <= '1';
					when others =>
						write_data_ram <= '0';
				end case;
			end if;
	end process;

	WriteRamData_proc : process (clk, RST)
	begin
		if RST = '1' then
			RW_REGISTER_BANK(0) <= (others => '0');
			RW_REGISTER_BANK(1) <= (others => '0');
			RW_REGISTER_BANK(2) <= (others => '0');
			RW_REGISTER_BANK(3) <= (others => '0');
			--RW_REGISTER_BANK(4) <= (others => '0');
			--RW_REGISTER_BANK(5) <= (others => '0');
			--RW_REGISTER_BANK(6) <= (others => '0');
			RW_REGISTER_BANK(7) <= (others => '0');
			RW_REGISTER_BANK(8) <= (others => '0');
			RW_REGISTER_BANK(9) <= (others => '0');

		elsif (rising_edge(clk)) then
			if write_data_ram = '1' then
				if(r_address_bus_in = "0000000000000000") then
					RW_REGISTER_BANK(0) <= r_data_bus_in;
				elsif(r_address_bus_in = "0000000000000001") then
					RW_REGISTER_BANK(1) <= r_data_bus_in;
				elsif(r_address_bus_in = "0000000000000010") then
					RW_REGISTER_BANK(2) <= r_data_bus_in;
				elsif(r_address_bus_in = "0000000000000011") then
					RW_REGISTER_BANK(3) <= r_data_bus_in;
				elsif(r_address_bus_in = "0000000000000111") then
					RW_REGISTER_BANK(7) <= r_data_bus_in;
				elsif(r_address_bus_in = "0000000000001000") then
					RW_REGISTER_BANK(8) <= r_data_bus_in;
				elsif(r_address_bus_in = "0000000000001001") then
					RW_REGISTER_BANK(9) <= r_data_bus_in;
				end if;
			end if;
		end if;
	end process;

	observer_StateMachine_Register_READ_proc : process (RegState)
	begin
		case RegState is
			when Idle=>
				data_bus_out <=  (others => '1');
				read_data_ram <= '0';
				enable_data_out <= '0';
			when ReadReg =>
				read_data_ram <= '1';
			when TXData =>
				read_data_ram <= '0';
				data_bus_out <= r_read_data;
				enable_data_out <= '1';
			when others =>
				read_data_ram <= '0';
				enable_data_out <= '0';
		end case;
	end process;


	read_reg_proc : process (clk, RST)
	begin
		if RST = '1' then
			r_read_data <= (others => '1');
		elsif (rising_edge(clk)) then
			if read_data_ram = '1' then
				if(r_address_bus_in = "0000000000000000") then
					r_read_data <= RW_REGISTER_BANK(0);
				elsif(r_address_bus_in = "0000000000000001") then
					r_read_data <= RW_REGISTER_BANK(1);
				elsif(r_address_bus_in = "0000000000000010") then
					r_read_data <= RW_REGISTER_BANK(2);
				elsif(r_address_bus_in = "0000000000000011") then
					r_read_data <= RW_REGISTER_BANK(3);
				elsif(r_address_bus_in = "0000000000000100") then
					r_read_data <= RW_REGISTER_BANK(4);
				elsif(r_address_bus_in = "0000000000000101") then
					r_read_data <= RW_REGISTER_BANK(5);
				elsif(r_address_bus_in = "0000000000000110") then
					r_read_data <= RW_REGISTER_BANK(6);
				elsif(r_address_bus_in = "0000000000000111") then
					r_read_data <= RW_REGISTER_BANK(7);
				elsif(r_address_bus_in = "0000000000001000") then
					r_read_data <= RW_REGISTER_BANK(8);
				elsif(r_address_bus_in = "0000000000001001") then
					r_read_data <= RW_REGISTER_BANK(9);
				end if;
			end if;
		end if;
	end process;


	process (clk, RST)
	begin
		if RST = '1' then
			shift_enb_data_out <= "1000";
		elsif (rising_edge(clk)) then
			if read_data_ram = '1' then
				shift_enb_data_out <= '0' & shift_enb_data_out(3 downto 1);
			else
				shift_enb_data_out <= "1000";
			end if;
		end if;
	end process;

	-- LED OUT
	process (clk, RST)
	begin
		if RST = '1' then
			reg_led <= (others => '1');
		elsif (rising_edge(clk)) then
			reg_led <= RW_REGISTER_BANK(0);
		end if;
	end process;

	-- Mapeamento do LED
	gpio_out <= reg_led(7 downto 0);

end rtl;
