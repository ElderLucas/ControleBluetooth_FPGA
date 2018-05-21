library ieee;
-- use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_1164.all;

entity filex is
    port (
        clk: in std_logic
    );
end entity filex;

architecture test of filex is
    signal d1,d2,d3: integer;
begin
    process (clk)
        variable  outline:      line;
        variable  inline:       line;
        variable  a:            integer;
        -- file input_file: text open read_mode is "c:\users\k56c\desktop\test.txt";
        file infile: text open read_mode is "test.txt";
        file outfile: text is out "outputlink";
    begin
        if not endfile (infile) then
            readline(infile, inline);
            read(inline , a );
            a := a + 10;
            write(outline, a);
            writeline(outfile, outline);
        end if;
    end process;
end architecture test;
