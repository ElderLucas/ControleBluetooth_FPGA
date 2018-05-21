library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity average_math is
    port (
        clock: in std_logic;
        reset: in std_logic;
        channel_1_sample: in signed(11 downto 0);
        channel_2_sample: in signed(11 downto 0);
        channel_1_average: out signed(11 downto 0);
        channel_2_average: out signed(11 downto 0)
    );
end;

architecture rtl of average_mathis

    signal average_1, average_2: integer;
    signal my_avr1 : std_logic_vector(11 downto 0);
    signal my_avr2 : std_logic_vector(11 downto 0);

    signal enb_data_out1_s : std_logic := '0';
    signal enb_data_out2_s : std_logic := '0';

    signal enb_data_in1_s : std_logic := '0';
    signal enb_data_in2_s : std_logic := '0';

begin

    channel_1: entity work.moving_average
        port map(
            CLK     => clock,
            RST     => reset,
            load    => enb_data_in1_s,
            sample  => to_integer(channel_1_sample),
            average => average_1,
            enb_data_out => enb_data_out1_s
        );

    channel_2: entity work.moving_average
        port map(
            CLK     => clock,
            RST     => reset,
            load    => enb_data_in2_s,
            sample  => to_integer(channel_2_sample),
            average => average_2,
            enb_data_out => enb_data_out2_s
        );

    my_avr1 <= std_logic_vector(to_unsigned(average_1, my_avr1'length));
    my_avr2 <= std_logic_vector(to_unsigned(average_2, my_avr1'length));

end;
