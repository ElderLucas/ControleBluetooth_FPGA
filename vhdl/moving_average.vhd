library ieee;
use ieee.std_logic_1164.all;

entity moving_average is
    generic(
        SAMPLES_COUNT: integer := 100
    );
    port (
        CLK: in std_logic;
        RST: in std_logic;
        load: in std_logic;
        sample: in integer;
        average: out integer;
        enb_data_out : out std_logic
    );
end;

architecture rtl of moving_average is


    signal count : integer;
    signal sum: integer;
    signal average_s: integer;

    signal shift_reg_s : std_logic_vector(1 downto 0) := (others => '0');

    signal enb_data_s : std_logic := '0';


    type RAM is array (0 to SAMPLES_COUNT-1) of integer range 0 to 4095;
    signal RAM_0 : RAM;

begin
    average_proc : process (CLK, RST) begin
        if rising_edge(CLK) then
            if RST = '1' then
                sum <= 0;
                count <= 0;
                enb_data_s <= '0';
                average_s <= 0;
            else
                if load = '1' then
                    if (count = 0) then
                        count <= count + 1;
                        sum <= sample;
                        enb_data_s <= '0';
                    elsif(count < SAMPLES_COUNT) then
                        count <= count + 1;
                        sum <= sum + sample;
                    else
                        count <= 0;
                        average_s <= sum / SAMPLES_COUNT;
                        enb_data_s <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    enb_data_out_proc : process (CLK, RST) begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                shift_reg_s <= (others => '0');
            else
                shift_reg_s <= shift_reg_s(0) & enb_data_s;
            end if;
        end if;
    end process;

    data_out_proc : process (CLK, RST) begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                enb_data_out <= '0';
            else
                if shift_reg_s = "01" then
                    enb_data_out <= '1';
                    average <= average_s;
                else
                    enb_data_out <= '0';
                    average <= 0;
                end if;
            end if;
        end if;
    end process;


end;
