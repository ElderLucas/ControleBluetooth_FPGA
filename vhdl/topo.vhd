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
    signal SCLKC_S	 		   :std_logic;
    signal SS_S	 			   :std_logic;
    signal MOSI_S	 		   :std_logic;
    signal MISO_S 	 		   :std_logic := '1';

    -- USER DATA INPUT INTERFACE
    signal DATA_IN             : std_logic_vector(7 downto 0); -- input data
    signal DATA_SEND           : std_logic; -- when DATA_SEND = 1, input data are valid and will be transmit
    signal BUSY                : std_logic; -- when BUSY = 1, transmitter is busy and you must not set DATA_SEND to 1

    -- USER DATA OUTPUT INTERFACE
    signal DATA_OUT            : std_logic_vector(7 downto 0); -- output data
    signal DATA_VLD            : std_logic; -- when DATA_VLD = 1, output data are valid
    signal FRAME_ERROR         : std_logic;  -- when FRAME_ERROR = 1, stop bit was invalid

    signal CONV_CH_SEL_S 	   :std_logic_vector(2 downto 0);
    signal CONV_ENB_S    	   :std_logic;
    signal DATA_VALID_S	 	:std_logic;
    signal ADC_CH_ADDRESS_S	:std_logic_vector(2 downto 0);
    signal ADC_DATAOUT_S	:std_logic_vector(11 downto 0);


    signal timer_1seg_s     : std_logic;
    signal Busy_s           : std_logic;
    signal DATA_OUT_S       : std_logic_vector(1 downto 0);

    signal RST_s            : std_logic := '1';


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
        UART_CLK_EN => uart_clk_en,
        UART_TXD    => UART_TXD,
        -- USER DATA INPUT INTERFACE
        DATA_IN     => DATA_IN,
        DATA_SEND   => DATA_SEND,
        BUSY        => BUSY
    );

    -- -------------------------------------------------------------------------
    -- UART RECEIVER
    -- -------------------------------------------------------------------------

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
        DATA_OUT    => DATA_OUT,
        DATA_VLD    => DATA_VLD,
        FRAME_ERROR => FRAME_ERROR
    );

    -- -------------------------------------------------------------------------
    -- ADC128S022
    -- -------------------------------------------------------------------------
    adc128s022: entity work.adc_serial_control
	generic map (
	    CLK_DIV   => 100  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)
	port map (
	    i_clk	=> CLK,
	    i_rstb  => RST_s,

	    i_conv_ena => CONV_ENB_S, 			-- enable ADC convesion
	    i_adc_ch => CONV_CH_SEL_S,			-- ADC channel 0-7
	    o_adc_data_valid => DATA_VALID_S, 	-- conversion valid pulse
	    o_adc_ch => ADC_CH_ADDRESS_S,  		-- ADC converted channel
	    o_adc_data => ADC_DATAOUT_S,        -- adc parallel data
	    -- ADC serial interface
	    o_sclk => SCLKC_S,
	    o_ss => SS_S,
	    o_mosi =>MOSI_S,
	    i_miso => MISO_IN
	);


    -- -------------------------------------------------------------------------
    -- Master controle
    -- -------------------------------------------------------------------------
    controlador : entity work.masterCTRL
	generic map (
	    CLK_DIV   => 100  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(CLK_DIV)
	)
	port map (
		clk	=> CLK,
		data_in => timer_1seg_s,
		reset  => RST_s,
		enb_adc_conv => CONV_ENB_S,
		ch_adc_conv => CONV_CH_SEL_S,
		busy => Busy_s,
		data_out => LED_OUT(1 downto 0)
	);


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

    LED_OUT(7) <= timer_1seg_s;
    LED_OUT(5 downto 2) <= (others => '1');
    LED_OUT(6) <= CONV_ENB_S;

    --LED_OUT(2 downto 0) <= ADC_CH_ADDRESS_S;

    RST_s <= not RST;

end full;
