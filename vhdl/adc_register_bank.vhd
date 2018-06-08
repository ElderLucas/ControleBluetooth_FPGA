-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity adc_register_bank is
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
        enable_data_in_ch0  : in    std_logic;
        ADC_Data_ch0		: in	std_logic_vector(11 downto 0); -- Canal 0
        enable_data_in_ch1  : in    std_logic;
        ADC_Data_ch1		: in	std_logic_vector(11 downto 0); -- Canal 1
        enable_data_in_ch2  : in    std_logic;
        ADC_Data_ch2		: in	std_logic_vector(11 downto 0); -- Canal 2
        enable_data_in_ch3  : in    std_logic;
        ADC_Data_ch3		: in	std_logic_vector(11 downto 0); -- Canal 3
        enable_data_in_ch4  : in    std_logic;
        ADC_Data_ch4		: in	std_logic_vector(11 downto 0); -- Canal 4
        enable_data_in_ch5  : in    std_logic;
        ADC_Data_ch5		: in	std_logic_vector(11 downto 0); -- Canal 5
        enable_data_in_ch6  : in    std_logic;
        ADC_Data_ch6		: in	std_logic_vector(11 downto 0); -- Canal 6
        enable_data_in_ch7  : in    std_logic;
        ADC_Data_ch7		: in	std_logic_vector(11 downto 0)  -- Canal 7

	);
end entity;

architecture rtl of adc_register_bank is

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

	----------------------------------------------------------------------------
	-- Palavras de habilitação dos Enables
	signal reg_enable_test	: std_logic_vector(15 downto 0);

	----------------------------------------------------------------------------
	-- Máquina de estados das operações dos blocos de registros do Módulo
	type state_reg_type is (Idle, WriteReg, ReadReg, UpdateReg, DeleteReg, WaitingProcess, AnswerAck);
	-- Criando a máquina de estados para controle das operações dos registros
	signal RegState : state_reg_type;

	-- BANCO DE REGISTROS DO Módulo - Cada Posição um Canal do ADC
	type RAM is array (0 to 7) of std_logic_vector(15 downto 0);
	signal RW_REGISTER_BANK : RAM;

	-- Contador de Tempo
	constant COUNTER_1SEG_TIMER : integer := 5000;--500000;
    signal timer_1seg_cnt       : integer := 0;
	signal TIMER_1SEG			: std_logic := '0';

	signal start_test			: std_logic := '0';

begin

	-- -------------------------------------------------------------------------
	-- UART CLOCK COUNTER AND CLOCK ENABLE FLAG
	-- -------------------------------------------------------------------------
	timer_counter_proc : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (RST = '1') then
				timer_1seg_cnt <= 0;
			else
				if (timer_1seg_cnt = COUNTER_1SEG_TIMER-1) then
					timer_1seg_cnt <= 0;
				else
					timer_1seg_cnt <= timer_1seg_cnt + 1;
				end if;
			end if;
		end if;
	end process;

	-- -------------------------------------------------------------------------
    -- UART CLOCK COUNTER AND CLOCK ENABLE FLAG
    -- -------------------------------------------------------------------------
    tic_proc : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                TIMER_1SEG <= '0';
            else
                if (timer_1seg_cnt = COUNTER_1SEG_TIMER-1) then
                    TIMER_1SEG <= '1';
                else
                    TIMER_1SEG <= '0';
                end if;
            end if;
        end if;
    end process;


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
	-- Máquina de estados de controle dos conversores AD
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

					-- ADC CH 2
					when convADC_Ch2=>
						if TIMER_1SEG = '1' then
							state <= convADC_Ch0;
						else
							state <= convADC_Ch2;
						end if;
				end case;
			end if;
		end if;
	end process;

	-- Output depends solely on the current state
	process (state)
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
	-- Máquina de estados dos registros dos Bloco
	----------------------------------------------------------------------------
	reg_proc : process (clk, RST)
	begin
		if RST = '1' then
			RegState <= Idle;
		elsif (rising_edge(clk)) then
			if enable_data_in = '1' and chip_select = '0' then
				case RegState is
					when Idle=>

						if crud_in = "0000" then 	--WriteReg
							RegState <= WriteReg;

						elsif crud_in = "0001" then --ReadReg
							RegState <= ReadReg;

						elsif crud_in = "0010" then --UpdateReg
							RegState <= UpdateReg;

						elsif crud_in = "0011" then --DeleteReg
							RegState <= DeleteReg;
						end if;

					-- Write states
					when WriteReg =>
						RegState <= AnswerAck;

					when ReadReg =>
						RegState <= AnswerAck;

					when UpdateReg =>
						RegState <= AnswerAck;

					when DeleteReg =>
						RegState <= AnswerAck;

					when AnswerAck =>
						RegState <= AnswerAck;

					when WaitingProcess =>
						RegState <= Idle;

				end case;
			else
				RegState <= Idle;
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Write Reg Procs
	----------------------------------------------------------------------------
	sm_write_reg_proc : process (clk, RST) -- State Machine Write Reg Proc
	begin
		if RST = '1' then
			write_data_ram <= '0';
		elsif (rising_edge(clk)) then
				case RegState is
					when Idle=>
						write_data_ram <= '0';
					when WriteReg =>
						r_address_bus_in <= address_in;
						r_data_bus_in <= data_in;
						write_data_ram <= '1';

					when others =>
						write_data_ram <= '0';
				end case;
			end if;
	end process;


    ----------------------------------------------------------------------------
    -- Processos de escrita nos REGISTROS do bloco
    ----------------------------------------------------------------------------
	channel0_reg_proc : process (clk, RST)
	begin
		if RST = '1' then
			RW_REGISTER_BANK(0) <= (others => '0');
		elsif (rising_edge(clk)) then
			if enable_data_in_ch0 = '1' then
                RW_REGISTER_BANK(0) <= "00000" & ADC_Data_ch0;
			end if;
		end if;
	end process;

    channel1_reg_proc : process (clk, RST)
    begin
        if RST = '1' then
            RW_REGISTER_BANK(1) <= (others => '0');
        elsif (rising_edge(clk)) then
            if enable_data_in_ch1 = '1' then
                RW_REGISTER_BANK(1) <= "00000" & ADC_Data_ch1;
            end if;
        end if;
    end process;

    channel2_reg_proc : process (clk, RST)
    begin
        if RST = '1' then
            RW_REGISTER_BANK(2) <= (others => '0');
        elsif (rising_edge(clk)) then
            if enable_data_in_ch2 = '1' then
                RW_REGISTER_BANK(2) <= "00000" & ADC_Data_ch2;
            end if;
        end if;
    end process;

    channel3_reg_proc : process (clk, RST)
    begin
        if RST = '1' then
            RW_REGISTER_BANK(3) <= (others => '0');
        elsif (rising_edge(clk)) then
            if enable_data_in_ch3 = '1' then
                RW_REGISTER_BANK(3) <= "00000" & ADC_Data_ch3;
            end if;
        end if;
    end process;

    channel4_reg_proc : process (clk, RST)
    begin
        if RST = '1' then
            RW_REGISTER_BANK(4) <= (others => '0');
        elsif (rising_edge(clk)) then
            if enable_data_in_ch4 = '1' then
                RW_REGISTER_BANK(4) <= "00000" & ADC_Data_ch4;
            end if;
        end if;
    end process;

    channel5_reg_proc : process (clk, RST)
    begin
        if RST = '1' then
            RW_REGISTER_BANK(5) <= (others => '0');
        elsif (rising_edge(clk)) then
            if enable_data_in_ch5 = '1' then
                RW_REGISTER_BANK(5) <= "00000" & ADC_Data_ch5;
            end if;
        end if;
    end process;

    channel6_reg_proc : process (clk, RST)
    begin
        if RST = '1' then
            RW_REGISTER_BANK(6) <= (others => '0');
        elsif (rising_edge(clk)) then
            if enable_data_in_ch6 = '1' then
                RW_REGISTER_BANK(6) <= "00000" & ADC_Data_ch6;
            end if;
        end if;
    end process;

    channel7_reg_proc : process (clk, RST)
    begin
        if RST = '1' then
            RW_REGISTER_BANK(7) <= (others => '0');
        elsif (rising_edge(clk)) then
            if enable_data_in_ch7 = '1' then
                RW_REGISTER_BANK(7) <= "00000" & ADC_Data_ch7;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    --





	----------------------------------------------------------------------------
	-- Read Proc
	----------------------------------------------------------------------------
	sm_read_reg_proc : process (clk, RST) -- State Machine Write Reg Proc
	begin
		if RST = '1' then
			read_data_ram <= '0';
			enable_data_out <= '0';
		elsif (rising_edge(clk)) then
			if enable_data_in = '1' then
				case RegState is
					when Idle=>
						r_address_bus_in <= address_in;
						r_data_bus_in <= data_in;

						read_data_ram <= '1';
						enable_data_out <= '0';

					when ReadReg =>
						read_data_ram <= '0';
						enable_data_out <= '1';

					when others =>
						read_data_ram <= '0';
						enable_data_out <= '0';

				end case;
			end if;
		end if;
	end process;



	read_reg_proc : process (clk, RST)
	begin
		if RST = '1' then
			data_bus_out <= (others => '1');
		elsif (rising_edge(clk)) then
			if read_data_ram = '1' then
				if(r_address_bus_in = "0000000000000000") then
					data_bus_out <= RW_REGISTER_BANK(0);
				elsif(r_address_bus_in = "0000000000000001") then
					data_bus_out <= RW_REGISTER_BANK(1);
				elsif(r_address_bus_in = "0000000000000010") then
					data_bus_out <= RW_REGISTER_BANK(2);
				elsif(r_address_bus_in = "0000000000000011") then
					data_bus_out <= RW_REGISTER_BANK(3);
				end if;
			end if;
		end if;
	end process;


end rtl;
