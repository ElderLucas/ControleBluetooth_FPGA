-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity masterCTRL is
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

		-- Saída de seleção do canal do AD que será habilitado para converter os dados
		enb_adc_conv 		: out	std_logic;
		ch_adc_conv 		: out	std_logic_vector(2 downto 0);

		-- Enable data in
		ADC_Enb_Data_in		: in 	std_logic_vector(7 downto 0);

		-- Entrada dos dados dos conversores AD
		ADC_Data_ch0		: in	std_logic_vector(11 downto 0); -- V_SENSE
		ADC_Data_ch1		: in	std_logic_vector(11 downto 0); -- I_DUT
		ADC_Data_ch2		: in	std_logic_vector(11 downto 0); -- DUT_IS
		ADC_Data_ch3		: in	std_logic_vector(11 downto 0);
		ADC_Data_ch4		: in	std_logic_vector(11 downto 0);
		ADC_Data_ch5		: in	std_logic_vector(11 downto 0);
		ADC_Data_ch6		: in	std_logic_vector(11 downto 0);
		ADC_Data_ch7		: in	std_logic_vector(11 downto 0);

		-- Sinaliza que está ocupado
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
	constant COUNTER_ADC_TIMER : integer := 5000;--500000;
    signal timer_adc_cnt       : integer := 0;
	signal TIMER_1SEG			: std_logic := '0';

	signal start_test			: std_logic := '0';

begin
	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	-- INICIO DOS PROCESSOS DE CONTROLE DOS CONVERSORES ADC
	----------------------------------------------------------------------------
	----------------------------------------------------------------------------

	----------------------------------------------------------------------------
	-- Processos para gerar base de tempo de inicio de cada conversão
	-- dos ADC's.
	--
	-- Cada "tic" inicial uma conversão.
	-- Neste formato de controle, não é mecessário ler o status dos ADCs
	-- e isso simplifica o processo de leitura, bastando apenas respeitar o
	-- tempo entre cada conversão.
	--
	----------------------------------------------------------------------------
	timer_counter_proc : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (RST = '1') then
				timer_adc_cnt <= 0;
			else
				if (timer_adc_cnt = COUNTER_ADC_TIMER-1) then
					timer_adc_cnt <= 0;
				else
					timer_adc_cnt <= timer_adc_cnt + 1;
				end if;
			end if;
		end if;
	end process;

    tic_proc : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                TIMER_1SEG <= '0';
            else
                if (timer_adc_cnt = COUNTER_ADC_TIMER-1) then
                    TIMER_1SEG <= '1';
                else
                    TIMER_1SEG <= '0';
                end if;
            end if;
        end if;
    end process;

	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	-- Máquina de estados de controle dos conversores AD
	-- A base de tempo para mudança de cada estado é baseada no "Tic" do
	-- processo 'tic_proc'
	--
	-- A ideia desse processo de controle das conversões é que cada canal seja
	-- selecionado de forma sequencia.
	--
	-- Para os testes iniciais, apenas os três canais menos significativos
	-- são leidos, sequêncialmente, 0 1 e 3.
	--
	-- Lembrando que a conversão está em "malha aberta" *** pois a leitura do
	-- status não está sendo feita.
	--
	-- *** Um dos motivos para isso ser desenvolvido assim é o fato de que se um
	-- outro conversor ADC for usado, basta ler o enable data out e o data out
	-- de tal ADC.
	--
	----------------------------------------------------------------------------
	----------------------------------------------------------------------------
	controle_ad_proc : process (clk, RST)
	begin
		if RST = '1' then
			state <= Idle;
		elsif (rising_edge(clk)) then
			if start_test = '1' then
				case state is
					when Idle=>
						if TIMER_1SEG = '1' then
							state <= convADC_Ch0;
						else
							state <= Idle;
						end if;

					-- ADC CH 0
					when convADC_Ch0=>
						if TIMER_1SEG = '1' then
							state <= convADC_Ch1;
						else
							state <= convADC_Ch0;
						end if;

					-- ADC CH 1
					when convADC_Ch1=>
						if TIMER_1SEG = '1' then
							state <= convADC_Ch2;
						else
							state <= convADC_Ch1;
						end if;

					-- ADC CH 2c
					when convADC_Ch2=>
						if TIMER_1SEG = '1' then
							state <= convADC_Ch0;
						else
							state <= convADC_Ch2;
						end if;
				end case;
			else
				state <= Idle;
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Processo para observar o estado da Máquina de estados e comandar uma
	-- Saída. As saídas controladas assumem valores de acordo com o estado
	-- da máquina de estados.
	----------------------------------------------------------------------------
	state_machine_observer_proc : process (state)
	begin
		case state is
			when Idle =>
				busy <= '0';
				enb_adc_conv <= '0';
				ch_adc_conv <= "000";

			when convADC_Ch0 =>
				enb_adc_conv <= '1';
				ch_adc_conv <= "000";

			when convADC_Ch1 =>
				enb_adc_conv <= '1';
				ch_adc_conv <= "001";

			when convADC_Ch2 =>
				enb_adc_conv <= '1';
				ch_adc_conv <= "010";

		end case;
	end process;
	----------------------------------------------------------------------------
	-- FIM DOS PROCESSOS DE CONTROLE DOS CONVERSORES ADC
	----------------------------------------------------------------------------
	----------------------------------------------------------------------------

	--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX--

	----------------------------------------------------------------------------
	-- INICIO DOS PROCESSOS DE CONTROLE INTERFACE COM O BARRAMENTO INTERNO
	----------------------------------------------------------------------------
	-- *** O barramento interno é o barramento de comunicação entre todos
	--     os blocos internos.
	----------------------------------------------------------------------------

	----------------------------------------------------------------------------
	-- Processos para Receber e registrar o ChipSelect do Barramento interno
	-- de Comunicação da FPGA.
	----------------------------------------------------------------------------
	chip_select_proc : process (clk, RST)
	begin
		if RST = '1' then
			r_chip_select <= '1';
		elsif (rising_edge(clk)) then
			r_chip_select <= chip_select;
		end if;
	end process;

	reg_enable_test_proc : process (clk, RST)
	begin
		if RST = '1' then
			reg_enable_test <= (others => '1');
		elsif (rising_edge(clk)) then
			reg_enable_test <= RW_REGISTER_BANK(0);
		end if;
	end process;

	ctrl_test_proc : process (clk, RST)
	begin
		if RST = '1' then
			start_test <= '0';
		elsif (rising_edge(clk)) then
			start_test <= reg_enable_test(0);
		end if;
	end process;

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
				--elsif(r_address_bus_in = "0000000000000001") then
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

	-- Enable Data Out
	--enable_data_out <= shift_enb_data_out(2);

	----------------------------------------------------------------------------
	-- Armazena os dados lidos do conversor AD
	--
	----------------------------------------------------------------------------
	loadADC_ch0_data : process (clk, RST)
	begin
		if RST = '1' then
			RW_REGISTER_BANK(4) <= (others => '0');
		elsif (rising_edge(clk)) then
			if ADC_Enb_Data_in(0) = '1' then
				RW_REGISTER_BANK(4) <= "0000" & ADC_Data_ch0(11 downto 0);
			end if;
		end if;
	end process;

	loadADC_ch1_data : process (clk, RST)
	begin
		if RST = '1' then
			RW_REGISTER_BANK(5) <= (others => '0');
		elsif (rising_edge(clk)) then
			if ADC_Enb_Data_in(1) = '1' then
				RW_REGISTER_BANK(5) <= "0000" & ADC_Data_ch1(11 downto 0);
			end if;
		end if;
	end process;

	loadADC_ch2_data : process (clk, RST)
	begin
		if RST = '1' then
			RW_REGISTER_BANK(6) <= (others => '0');
		elsif (rising_edge(clk)) then
			if ADC_Enb_Data_in(2) = '1' then
				RW_REGISTER_BANK(6) <= "0000" & ADC_Data_ch2(11 downto 0);
			end if;
		end if;
	end process;



end rtl;
