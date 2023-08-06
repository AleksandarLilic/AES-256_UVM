library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ADD_SUB_L is
    Port (
        clk     : in STD_LOGIC;
        a0      : in STD_LOGIC_VECTOR(7 downto 0);
        b0      : in STD_LOGIC_VECTOR(7 downto 0);
        doAdd0  : in STD_LOGIC;
        result0 : out STD_LOGIC_VECTOR(8 downto 0)
    );
end ADD_SUB_L;

architecture Behavioral of ADD_SUB_L is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if doAdd0 = '1' then
                result0 <= std_logic_vector(resize(unsigned(a0) + unsigned(b0), 9));
            else
                result0 <= std_logic_vector(resize(unsigned(a0) - unsigned(b0), 9));
            end if;
        end if;
    end process;
end Behavioral;
