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

entity slice16to8bitsTX is
    Generic (
        CLK_FREQ      : integer := 50e6   -- system clock frequency in Hz
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- 16 Bits input
        DATA_IN     : in  std_logic_vector(15 downto 0); -- input data
        EN_DATA_IN  : in  std_logic; -- high active synchronous reset

        -- 8 Bits output
        DATA_OUT    : out  std_logic_vector(7 downto 0); -- input data
        EN_DATA_OUT : out  std_logic; -- high active synchronous reset

        -- Read UART Status
        READ_BUSY   : in std_logic
    );
end slice16to8bitsTX;

-- -------------------------------------------------------------------------
-- Contador de Tempo
-- -------------------------------------------------------------------------
architecture FULL of slice16to8bitsTX is

	constant COUNTER_1SEG_TIMER : integer := 500000;

    signal data_reg_s : std_logic_vector(DATA_IN'length - 1 downto 0) := (others => '0');
    signal data_out_s : std_logic_vector(2 downto 0) := (others => '0');

    type state is (idle, word1, word2, busy, wait_tx);
    signal tx_state : state;

    signal reg_busy_s       : std_logic_vector(1 downto 0) := (others => '0');
    signal enb_data_out_s   : std_logic;

begin

    -- -------------------------------------------------------------------------
	-- INPUT DATA - OK TESTADO
	-- -------------------------------------------------------------------------
	input_data_reg_proc : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (RST = '1') then
				data_reg_s <= (others => '0');
			else
				if (EN_DATA_IN = '1') then
					data_reg_s <= DATA_IN;
				else
					data_reg_s <= data_reg_s;
				end if;
			end if;
		end if;
	end process;

    -- -------------------------------------------------------------------------
    -- INPUT DATA - OK TESTADO
    -- -------------------------------------------------------------------------
    data_en_out_proc : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                data_out_s <= (others => '0');
            else
                if (EN_DATA_IN = '1') then
                    data_out_s <= "001";
                else
                    data_out_s <= data_out_s(data_out_s'length - 2   downto 0) & '0';
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- INPUT DATA
    -- -------------------------------------------------------------------------
    --data_out_proc : process (CLK)
    --begin
    --    if (rising_edge(CLK)) then
    --        if (RST = '1') then
    --            DATA_OUT <= (others => '0');
    --        else
    --            if (data_out_s(0) = '1') then
    --                DATA_OUT <= data_reg_s(7 downto 0);
    --            elsif (data_out_s(1) = '1') then
    --                DATA_OUT <= data_reg_s(15 downto 8);
    --            end if;
    --        end if;
    --    end if;
    --end process;


    -- -------------------------------------------------------------------------
    -- PRO BUSY UART
    -- -------------------------------------------------------------------------
    busy_proc : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                reg_busy_s <= (others => '0');
            else
                reg_busy_s <= reg_busy_s(0) & READ_BUSY;
            end if;
        end if;
    end process;


    -- -------------------------------------------------------------------------
    -- READ BUSY REG PROC
    -- -------------------------------------------------------------------------
    enb_data_out_proc : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                enb_data_out_s <= '0';
            else
                if (reg_busy_s = "10") then
                    enb_data_out_s <= '1';
                else
                    enb_data_out_s <= '0';
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- State Machine
    ----------------------------------------------------------------------------
	process (CLK, RST)
	begin
		if RST = '1' then
			tx_state <= Idle;
		elsif (rising_edge(CLK)) then
			case tx_state is
				when Idle=>
					if EN_DATA_IN = '1' then
						tx_state <= wait_tx;
					else
						tx_state <= Idle;
					end if;

                when wait_tx=>
                    if READ_BUSY = '0' then
                        tx_state <= word1;
                    else
                        tx_state <= wait_tx;
                    end if;

				when word1=>
					tx_state <= busy;

                when busy =>
                    if enb_data_out_s = '1' then
                        tx_state <= word2;
                    else
                        tx_state <= busy;
                    end if;

                when word2=>
                    tx_state <= Idle;
			end case;
		end if;
	end process;

	--Output depends solely on the current state
	process (tx_state, RST)
	begin
        if RST = '1' then
            DATA_OUT <= (others => '0');
        else
            case tx_state is
                when Idle =>
                    --DATA_OUT <= (others => '0');
                    EN_DATA_OUT <= '0';

                when wait_tx =>

                when busy =>
                    --DATA_OUT <= (others => '0');
                    EN_DATA_OUT <= '0';
                when word1 =>
                    DATA_OUT <= data_reg_s(7 downto 0);
                    EN_DATA_OUT <= '1';
                when word2 =>
                    DATA_OUT <= data_reg_s(15 downto 8);
                    EN_DATA_OUT <= '1';


            end case;
        end if;
	end process;

end FULL;
