--
-- Test bench for PRNG "xoroshiro128+".
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_xoroshiro128plus is
end entity;

architecture arch of tb_xoroshiro128plus is

    signal clk:             std_logic;
    signal clock_active:    boolean := false;

    signal s_rst:           std_logic;
    signal s_enable:        std_logic;
    signal s_reseed:        std_logic;
    signal s_newseed:       std_logic_vector(127 downto 0);
    signal s_output:        std_logic_vector(63 downto 0);

    function to_hex_string(s: std_logic_vector)
        return string
    is
        constant alphabet: string(1 to 16) := "0123456789abcdef";
        variable y: string(1 to s'length/4);
    begin
        for i in y'range loop
            y(i) := alphabet(to_integer(unsigned(s(s'high+4-4*i downto s'high+1-4*i))) + 1);
        end loop;
        return y;
    end function;

begin

    -- Instantiate PRNG.
    inst_prng: entity work.xoroshiro128plus
        generic map (
            init_seed => x"0123456789abcdef3141592653589793" )
        port map (
            clk     => clk,
            rst     => s_rst,
            enable  => s_enable,
            reseed  => s_reseed,
            newseed => s_newseed,
            output  => s_output );

    -- Generate clock.
    clk <= (not clk) after 10 ns when clock_active else '0';

    -- Main simulation process.
    process is
    begin

        report "Start test bench";

        -- Reset.
        s_rst       <= '1';
        s_enable    <= '0';
        s_reseed    <= '0';
        s_newseed   <= (others => '0');

        -- Start clock.
        clock_active    <= true;

        -- Wait 2 clock cycles, then end reset.
        wait for 30 ns;
        wait until falling_edge(clk);
        s_rst       <= '0';

        -- Produce numbers
        for i in 0 to 150 loop

            if i mod 5 = 0 or i mod 7 = 0 then
                s_enable    <= '0';
                wait until falling_edge(clk);
            else
                s_enable    <= '1';
                wait until falling_edge(clk);
                report "Got 0x" & to_hex_string(s_output);
            end if;

        end loop;

        -- Re-seed generator.
        report "Re-seed generator";
        s_enable    <= '1';
        s_reseed    <= '1';
        s_newseed   <= x"3141592653589793fedcba9876543210";
        wait until falling_edge(clk);

        s_reseed    <= '0';
        s_newseed   <= (others => '0');

        -- Produce numbers
        for i in 0 to 150 loop

            if i mod 5 = 0 or i mod 7 = 0 then
                s_enable    <= '0';
                wait until falling_edge(clk);
            else
                s_enable    <= '1';
                wait until falling_edge(clk);
                report "Got 0x" & to_hex_string(s_output);
            end if;

        end loop;

        -- End simulation.
        report "End testbench";

        clock_active    <= false;
        wait;

    end process;

end architecture;
