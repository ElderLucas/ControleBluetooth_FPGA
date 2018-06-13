--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart_for_fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


-- UART FOR FPGA REQUIRES: 1 START BIT, 8 DATA BITS, 1 STOP BIT!!!
-- OTHER PARAMETERS CAN BE SET USING GENERICS.

entity topo is
    Generic (
        CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
        BAUD_RATE     : integer := 115200; -- baud rate value
        PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_TXD    : out std_logic; -- serial transmit data
        UART_RXD    : in  std_logic; -- serial receive data

        -- LED SMD
        LED_OUT    : out std_logic_vector(7 downto 0); -- input data

        -- ADC128S22 SERIAL INTERFACE
        SCLK_OUT    : out std_logic;
        SS_OUT      : out std_logic;
        MOSI_OUT    : out std_logic;
        MISO_IN     : in  std_logic
    );
end topo;

architecture full of topo is

    constant DIVIDER_VALUE    : integer := CLK_FREQ/(16*BAUD_RATE);
    constant CLK_CNT_WIDTH    : integer := integer(ceil(log2(real(DIVIDER_VALUE))));
    constant CLK_CNT_MAX      : unsigned := to_unsigned(DIVIDER_VALUE-1, CLK_CNT_WIDTH);

    signal uart_clk_cnt       : unsigned(CLK_CNT_WIDTH-1 downto 0);
    signal uart_clk_en        : std_logic;
    signal uart_rxd_shreg     : std_logic_vector(3 downto 0);
    signal uart_rxd_debounced : std_logic;

    -- DATA ADC SIGNALS
    signal SCLKC_S	 		:std_logic;
    signal SS_S	 			:std_logic;
    signal MOSI_S	 		:std_logic;
    signal MISO_S 	 		:std_logic := '1';

    -- USER DATA INPUT INTERFACE
    signal DATA_IN          : std_logic_vector(7 downto 0); -- input data
    signal DATA_SEND        : std_logic; -- when DATA_SEND = 1, input data are valid and will be transmit
    signal BUSY             : std_logic; -- when BUSY = 1, transmitter is busy and you must not set DATA_SEND to 1

    -- USER DATA OUTPUT INTERFACE
    signal DATA_OUT         : std_logic_vector(7 downto 0); -- output data
    signal DATA_VLD         : std_logic; -- when DATA_VLD = 1, output data are valid
    signal FRAME_ERROR      : std_logic;  -- when FRAME_ERROR = 1, stop bit was invalid

    signal conv_ch_sel_s 	:std_logic_vector(2 downto 0);
    signal conv_enb_s    	:std_logic;
    signal data_valid_s	 	:std_logic;
    signal adc_ch_address_s	:std_logic_vector(2 downto 0);
    signal adc_dataout_s	:std_logic_vector(11 downto 0);

    signal adc_dataout_ch0_s	:std_logic_vector(11 downto 0);
    signal adc_dataout_ch1_s	:std_logic_vector(11 downto 0);
    signal adc_dataout_ch2_s	:std_logic_vector(11 downto 0);


    signal timer_1seg_s     : std_logic;
    signal Busy_s           : std_logic;
    signal DATA_OUT_S       : std_logic_vector(1 downto 0);

    signal RST_s            : std_logic := '1';

    -------------- Average CHA 1
    signal load_adc_ch0_s           : std_logic := '0';
    signal load_adc_ch1_s           : std_logic := '0';
    signal load_adc_ch2_s           : std_logic := '0';

    signal adc_data_ch0_s           : integer := 0;
    signal adc_data_ch1_s           : integer := 0;
    signal adc_data_ch2_s           : integer := 0;

    signal avg_adc_data_ch0_s       : integer := 0;
    signal avg_adc_data_ch1_s       : integer := 0;
    signal avg_adc_data_ch2_s       : integer := 0;

    signal enb_data_ch0_out         : std_logic := '0';
    signal enb_data_ch1_out         : std_logic := '0';
    signal enb_data_ch2_out         : std_logic := '0';

    signal showFpgaStatus           : std_logic := '0';
    signal fromUartTxBusy           : std_logic := '0';

    signal showFPGA_Status          : std_logic := '0';
    signal fromUART_TX_BUSY         : std_logic := '0';
    signal rDATA_VLD                : std_logic := '0';
    signal rDATA_OUT                : std_logic_vector(7 downto 0) := (others => '0');
    signal DATA_Protoco2UartTX_en   : std_logic := '0';
    signal DATA_Protoco2UartTX      : std_logic_vector(7 downto 0) := (others => '0');

    signal r_data_bus_in             : std_logic_vector(15 downto 0) := (others => '0');
    signal r_data_bus_out            : std_logic_vector(15 downto 0) := (others => '0');
    signal r_Address_bus_out         : std_logic_vector(15 downto 0) := (others => '0');
    signal r_Command_bus_out         : std_logic_vector(7 downto 0) := (others => '0');
    signal r_data_bus_cs             : std_logic_vector(15 downto 0) := (others => '0');
    signal r_data_bus_en_o           : std_logic := '0';
    signal r_data_bus_en_i           : std_logic := '0';
    signal r_data_bus_rw             : std_logic_vector(3 downto 0) := (others => '0');
    signal r_data_bus_crud           : std_logic_vector(3 downto 0) := (others => '0');

    signal To_UartTx                 : std_logic_vector(15 downto 0) := (others => '0');
    signal Enb_To_UartTx             : std_logic := '0';
    signal ADC_Enb_Data_s		     : std_logic_vector(7 downto 0);

    signal avg_adc_ch0: std_logic_vector(11 downto 0);
    signal avg_adc_ch1: std_logic_vector(11 downto 0);
    signal avg_adc_ch2: std_logic_vector(11 downto 0);

    signal tx_busy       : std_logic := '0';
    signal tx_uart       : std_logic := '1';
    signal rx_uart       : std_logic := '1';
    signal uart_busy     : std_logic := '1';


begin

    -- -------------------------------------------------------------------------
    -- UART CLOCK COUNTER AND CLOCK ENABLE FLAG
    -- -------------------------------------------------------------------------
    uart_clk_cnt_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST_s = '1') then
                uart_clk_cnt <= (others => '0');
            else
                if (uart_clk_cnt = CLK_CNT_MAX) then
                    uart_clk_cnt <= (others => '0');
                else
                    uart_clk_cnt <= uart_clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    uart_clk_en_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST_s = '1') then
                uart_clk_en <= '0';
            elsif (uart_clk_cnt = CLK_CNT_MAX) then
                uart_clk_en <= '1';
            else
                uart_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RXD SHIFT REGISTER AND DEBAUNCER
    -- -------------------------------------------------------------------------

    use_debouncer_g : if (USE_DEBOUNCER = True) generate
        uart_rxd_shreg_p : process (CLK)
        begin
            if (rising_edge(CLK)) then
                if (RST_s = '1') then
                    uart_rxd_shreg <= (others => '1');
                else
                    uart_rxd_shreg <= UART_RXD & uart_rxd_shreg(3 downto 1);
                end if;
            end if;
        end process;

        uart_rxd_debounced_reg_p : process (CLK)
        begin
            if (rising_edge(CLK)) then
                if (RST_s = '1') then
                    uart_rxd_debounced <= '1';
                else
                    uart_rxd_debounced <= uart_rxd_shreg(0) OR
                                          uart_rxd_shreg(1) OR
                                          uart_rxd_shreg(2) OR
                                          uart_rxd_shreg(3);
                end if;
            end if;
        end process;
    end generate;

    not_use_debouncer_g : if (USE_DEBOUNCER = False) generate
        uart_rxd_debounced <= UART_RXD;
    end generate;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER
    -- -------------------------------------------------------------------------
    uart_tx_i: entity work.UART_TX
    generic map (
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK         => CLK,
        RST         => RST_s,

        -- UART INTERFACE
        UART_CLK_EN => '1',-- uart_clk_en,
        UART_TXD    => UART_TXD,

        -- USER DATA INPUT INTERFACE
        DATA_IN     => DATA_Protoco2UartTX,
        DATA_SEND   => DATA_Protoco2UartTX_en,

        BUSY        => tx_busy
    );

    ----------------------------------------------------------------------------
    -- UART RECEIVER
    ----------------------------------------------------------------------------
    uart_rx_i: entity work.UART_RX
    generic map (
        PARITY_BIT  => PARITY_BIT
    )
    port map (
        CLK         => CLK,
        RST         => RST_s,
        -- UART INTERFACE
        UART_CLK_EN => uart_clk_en,
        UART_RXD    => uart_rxd_debounced,
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT    => rDATA_OUT,
        DATA_VLD    => rDATA_VLD,
        FRAME_ERROR => FRAME_ERROR
    );


    uart: entity work.UART
    generic map (
        CLK_FREQ    => 50e6,
        BAUD_RATE   => 115200,
        PARITY_BIT  => "none"
    )
    port map (
        CLK         => CLK,
        RST         => RST_s,
        -- UART INTERFACE
        UART_TXD    => tx_uart,
        UART_RXD    => rx_uart,
        -- USER DATA INPUT INTERFACE
        DATA_OUT    => open,
        DATA_VLD    => open,
        FRAME_ERROR => open,
        -- USER DATA OUTPUT INTERFACE
        DATA_IN     => DATA_Protoco2UartTX,
        DATA_SEND   => DATA_Protoco2UartTX_en,
        BUSY        => uart_busy
    );



    protocolo_rx: entity work.PROTOCOLO
    generic map (
        CLK_DIV    => 100
    )
    port map (
        CLK             => CLK,
        RST             => RST_s,

        -- Sinais de Status Interno da FPGA usado
        -- para sinalizar que internamente a FPGA está em
        -- alguma tarefa
        fpga_busy_out   => showFPGA_Status,

        -- Sinal de entrada usado para saber se a UART ainda está transmitindo
        -- infromações
        uart_tx_busy_in => tx_busy,

        ------------------------------------------------------------------------
        ------------------ INTERFACE PARALELA ----------------------------------
        -- Recebe os dados Paralelos vindos da UART RX
        data_en_in      => rDATA_VLD,
        data_in 	    => rDATA_OUT,

        -- Transmite dados Paralelos para UART TX
        data_en_out     => DATA_Protoco2UartTX_en,
        data_out        => DATA_Protoco2UartTX,
        ------------------------------------------------------------------------

        ----------------- BARRAMENTO DE COMUNICAÇÃO ----------------------------
        -- Sinais de Dados de Entrada no bloco, vindo do Barramento
        data_bus_in     => r_data_bus_in,
        enable_in       => r_data_bus_en_i,

        -- Sinais de Dados de Saída do bloco, vindo do Barramento
        data_bus_out    => r_data_bus_out,
        enable_out      => r_data_bus_en_o,

        -- Sinais de Controle
        address_bus_out => r_Address_bus_out,
        chip_select     => r_data_bus_cs,
        crud_out        => r_data_bus_crud
    );

    -- -------------------------------------------------------------------------
    -- Master controle ADC
    -- -------------------------------------------------------------------------
    controlador : entity work.masterCTRL
    generic map (
        CLK_DIV   => 100  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
    )port map (
        CLK => CLK,
		RST	=> RST_s,

        -- Entrada de dados
        data_in         => r_data_bus_out,
        address_in      => r_Address_bus_out,
        crud_in         => r_data_bus_crud,
        enable_data_in  => r_data_bus_en_o,
        chip_select     => r_data_bus_cs(0),

        -- Saida de dados
		data_bus_out    => r_data_bus_in,
		enable_data_out => r_data_bus_en_i,

		-- Saída de seleção do canal do AD que será habilitado para converter os dados
		enb_adc_conv => CONV_ENB_S,
		ch_adc_conv => CONV_CH_SEL_S,

        -- Enable data in
        ADC_Enb_Data_in => ADC_Enb_Data_s,

		-- Entradas dos canais analógicos para testes das tensões e níveis
		ADC_Data_ch0 => avg_adc_ch0,
		ADC_Data_ch1 => avg_adc_ch1,
		ADC_Data_ch2 => avg_adc_ch2,
		ADC_Data_ch3 => "000000000000",
		ADC_Data_ch4 => "000000000000",
		ADC_Data_ch5 => "000000000000",
		ADC_Data_ch6 => "000000000000",
		ADC_Data_ch7 => "000000000000",

        --Sinalização de Busy
        busy => Busy_s

    );

    ADC_Enb_Data_s <= "00000" & enb_data_ch2_out & enb_data_ch1_out & enb_data_ch0_out;


    avg_adc_ch0 <= std_logic_vector(to_unsigned(avg_adc_data_ch0_s,avg_adc_ch0'length));
    avg_adc_ch1 <= std_logic_vector(to_unsigned(avg_adc_data_ch1_s,avg_adc_ch1'length));
    avg_adc_ch2 <= std_logic_vector(to_unsigned(avg_adc_data_ch2_s,avg_adc_ch2'length));


    -- -------------------------------------------------------------------------
    -- ADC128S022
    -- -------------------------------------------------------------------------
    adc128s022: entity work.adc_serial_control
	generic map (
	    CLK_DIV   => 100  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)port map (
	    i_clk	=> CLK,
	    i_rstb  => RST_s,

	    i_conv_ena => CONV_ENB_S, 			-- enable ADC convesion
	    i_adc_ch => CONV_CH_SEL_S,			-- ADC channel 0-7

        -- AD Converted Data
	    o_adc_data_valid => DATA_VALID_S, 	-- conversion valid pulse
	    o_adc_ch => ADC_CH_ADDRESS_S,  		-- ADC converted channel
	    o_adc_data => ADC_DATAOUT_S,        -- adc parallel data

	    -- ADC serial interface
	    o_sclk => SCLKC_S,
	    o_ss => SS_S,
	    o_mosi => MOSI_S,
	    i_miso => MISO_IN
	);

    ----------------------------------------------------------------------------
    -- ADC CH0 -- V SENSE
    ----------------------------------------------------------------------------
    channel_0: entity work.moving_average
    generic map (
        SAMPLES_COUNT    => 50
    )
    port map(
        CLK     => CLK,
        RST     => RST_s,
        load    => load_adc_ch0_s,
        sample  => adc_data_ch0_s, --to_integer(channel_1_sample),
        average => avg_adc_data_ch0_s,
        enb_data_out => enb_data_ch0_out
    );
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- ADC CH1 -- DUT_IS
    ----------------------------------------------------------------------------
    channel_1: entity work.moving_average
    generic map (
        SAMPLES_COUNT    => 50
    )
    port map(
        CLK     => CLK,
        RST     => RST_s,
        load    => load_adc_ch1_s,
        sample  => adc_data_ch1_s, --to_integer(channel_1_sample),
        average => avg_adc_data_ch1_s,
        enb_data_out => enb_data_ch1_out
    );
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- ADC CH2 -- I_DUT
    ----------------------------------------------------------------------------
    channel_2: entity work.moving_average
    generic map (
        SAMPLES_COUNT    => 50
    )
    port map(
        CLK     => CLK,
        RST     => RST_s,
        load    => load_adc_ch2_s,
        sample  => adc_data_ch2_s, --to_integer(channel_1_sample),
        average => avg_adc_data_ch2_s,
        enb_data_out => enb_data_ch2_out
    );
    ----------------------------------------------------------------------------

    -- ADC128S22
    SCLK_OUT   <=  SCLKC_S;
    SS_OUT     <=  SS_S;
    MOSI_OUT   <=  MOSI_S;

    -- -------------------------------------------------------------------------
    -- Timer de 1s
    -- -------------------------------------------------------------------------
    tic_1segundo: entity work.timer
	generic map (
	    CLK_FREQ   => 50e6  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)
	port map (
		clk	=> CLK,
		RST  => RST_s,
		TIMER_1SEG => timer_1seg_s
	);

    ----------------------------------------------------------------------------
    -- PROC SELEC AVERAGE BY AD CHANNEL ADDRESS
    ----------------------------------------------------------------------------
    select_adc_channel_proc : process (CLK, RST_s) begin
        if (rising_edge(CLK)) then
            if (RST_s = '1') then
                load_adc_ch0_s <= '0';
                load_adc_ch1_s <= '0';
                load_adc_ch2_s <= '0';

                adc_data_ch0_s <= 0;
                adc_data_ch1_s <= 0;
                adc_data_ch2_s <= 0;
            else
                if DATA_VALID_S = '1' then
                    if ADC_CH_ADDRESS_S = "000" then
                        -- data ch0
                        adc_data_ch0_s <= conv_integer(ADC_DATAOUT_S);--to_integer(unsigned(ADC_DATAOUT_S));  --to_unsigned(va, A'length); -- conv_integer(ADC_DATAOUT_S);-- to_integer(ADC_DATAOUT_S);
                        adc_dataout_ch0_s <= ADC_DATAOUT_S;
                        adc_data_ch1_s <= 0;
                        adc_data_ch2_s <= 0;
                        -- enable ch0
                        load_adc_ch0_s <= '1';
                        load_adc_ch1_s <= '0';
                        load_adc_ch2_s <= '0';

                    elsif ADC_CH_ADDRESS_S = "001" then
                        -- data ch1
                        adc_data_ch0_s <= 0;
                        adc_data_ch1_s <= conv_integer(ADC_DATAOUT_S);--to_integer(ADC_DATAOUT_S);
                        adc_dataout_ch1_s <= ADC_DATAOUT_S;
                        adc_data_ch2_s <= 0;
                        -- enable ch1
                        load_adc_ch0_s <= '0';
                        load_adc_ch1_s <= '1';
                        load_adc_ch2_s <= '0';

                    elsif ADC_CH_ADDRESS_S = "010" then
                        -- data ch2
                        adc_data_ch0_s <= 0;
                        adc_data_ch1_s <= 0;
                        adc_data_ch2_s <= conv_integer(ADC_DATAOUT_S);--to_integer(ADC_DATAOUT_S);
                        adc_dataout_ch2_s <= ADC_DATAOUT_S;
                        -- enable ch2
                        load_adc_ch0_s <= '0';
                        load_adc_ch1_s <= '0';
                        load_adc_ch2_s <= '1';

                    end if;

                else
                    load_adc_ch0_s <= '0';
                    load_adc_ch1_s <= '0';
                    load_adc_ch2_s <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    --
    ----------------------------------------------------------------------------
    LED_OUT(7) <= timer_1seg_s;
    LED_OUT(5 downto 2) <= (others => '1');
    LED_OUT(6) <= CONV_ENB_S;

    -- Inversão do Reset para a lógica dos blocos ativos em '1'
    RST_s <= RST;

end full;
