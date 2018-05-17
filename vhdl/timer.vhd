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

entity TIMER is
    Generic (
        CLK_FREQ      : integer := 50e6   -- system clock frequency in Hz
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- TIMER 1
        TIMER_1SEG   : out std_logic
    );
end TIMER;

-- -------------------------------------------------------------------------
-- Contador de Tempo
-- -------------------------------------------------------------------------
architecture FULL of TIMER is

	constant COUNTER_1SEG_TIMER : integer := 500000;

    signal timer_1seg_cnt       : unsigned(24 downto 0) := "0000000000000000000000000";

begin


	-- -------------------------------------------------------------------------
	-- UART CLOCK COUNTER AND CLOCK ENABLE FLAG
	-- -------------------------------------------------------------------------
	timer_counter_proc : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (RST = '1') then
				timer_1seg_cnt <= (others => '0');
			else
				if (timer_1seg_cnt = COUNTER_1SEG_TIMER-1) then
					timer_1seg_cnt <= (others => '0');
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


end FULL;
