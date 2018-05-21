--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  TESTBANCH OF UART TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart_for_fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity average_tb is
end average_tb;

architecture FULL of average_tb is

	signal CLK           	: std_logic := '0';
	signal RST           	: std_logic := '0';

    constant clk_period  : time := 20 ns;

    signal average_1, average_2: integer;
    signal sample_data: integer := 0;
    signal my_avr1 : std_logic_vector(11 downto 0);
    signal my_avr2 : std_logic_vector(11 downto 0);

    signal channel_1_sample : std_logic_vector(11 downto 0);

    signal enb_data_out1_s : std_logic := '0';
    signal enb_data_out2_s : std_logic := '0';

    signal enb_data_in1_s : std_logic := '0';
    signal enb_data_in2_s : std_logic := '0';

begin

    channel_1: entity work.moving_average
    generic map (
        SAMPLES_COUNT    => 100
    )
    port map(
        CLK     => CLK,
        RST     => RST,
        load    => enb_data_in1_s,
        sample  => sample_data, --to_integer(channel_1_sample),
        average => average_1,
        enb_data_out => enb_data_out1_s
    );



	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;


	reset_ctrl : process
	begin
		RST <= '1';
		wait for 100 ns;
		RST <= '0';
		wait;
	end process;

    values_gen : process
    begin

        if RST = '1' then
            enb_data_in1_s <= '0';
            sample_data <= 0;
        else
            --Enable data input
            wait for 100 us;

            for I in 0 to 14 loop
                wait until rising_edge(CLK);
                enb_data_in1_s <= '1';
                sample_data <= 20;
                wait until rising_edge(CLK);
                enb_data_in1_s <= '0';
        	end loop;


            for I in 0 to 14 loop
                wait until rising_edge(CLK);
                enb_data_in1_s <= '1';
                sample_data <= 10;
                wait until rising_edge(CLK);
                enb_data_in1_s <= '0';
            end loop;


            for I in 0 to 60 loop
                wait until rising_edge(CLK);
                enb_data_in1_s <= '1';
                sample_data <= 5;
                wait until rising_edge(CLK);
                enb_data_in1_s <= '0';
            end loop;

            for I in 0 to 600 loop
                wait until rising_edge(CLK);
                enb_data_in1_s <= '1';
                sample_data <= 125;
                wait until rising_edge(CLK);
                enb_data_in1_s <= '0';
            end loop;

            wait;

        end if;

    end process;


end FULL;
