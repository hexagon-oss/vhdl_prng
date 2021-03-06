--
-- Test bench for PRNG MT19937.
--

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mt19937 is
end entity;

architecture arch of tb_mt19937 is

    signal clk:             std_logic;
    signal clock_active:    boolean := false;

    signal s_rst:           std_logic;
    signal s_reseed:        std_logic;
    signal s_newseed:       std_logic_vector(31 downto 0);
    signal s_ready:         std_logic;
    signal s_valid:         std_logic;
    signal s_data:          std_logic_vector(31 downto 0);

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
    inst_prng: entity work.rng_mt19937
        generic map (
            init_seed => x"31415926",
            force_const_mul => false )
        port map (
            clk         => clk,
            rst         => s_rst,
            reseed      => s_reseed,
            newseed     => s_newseed,
            out_ready   => s_ready,
            out_valid   => s_valid,
            out_data    => s_data );

    -- Generate clock.
    clk <= (not clk) after 10 ns when clock_active else '0';

    -- Main simulation process.
    process is
        file outf1: text is out "sim_mt19937_seed1.dat";
        file outf2: text is out "sim_mt19937_seed2.dat";
        file outf3: text is out "sim_mt19937_seed3.dat";
        variable lin: line;
        variable nskip: integer;
        variable v: std_logic_vector(31 downto 0);
    begin

        report "Start test bench";

        -- Reset.
        s_rst       <= '1';
        s_reseed    <= '0';
        s_newseed   <= (others => '0');
        s_ready     <= '0';

        -- Start clock.
        clock_active    <= true;

        -- Wait 2 clock cycles, then end reset.
        wait for 30 ns;
        wait until falling_edge(clk);
        s_rst       <= '0';

        -- Give generator time to complete initialization.
        for i in 0 to 4*624 loop
            assert s_valid = '0' report "Generator indicates VALID too early";
            wait until falling_edge(clk);
        end loop;

        -- Start producing numbers.
        s_ready     <= '1';

        -- Produce numbers
        for i in 0 to 999 loop

            -- Check that output is valid.
            assert s_valid = '1' report "Output not VALID";

            -- Write output to file.
            write(lin, "0x" & to_hex_string(s_data));
            writeline(outf1, lin);

            -- Sometimes skip cycles.
            if i mod 5 = 1 then
                nskip := 1;
                if i mod 3 = 0 then
                    nskip := nskip + 1;
                end if;
                if i mod 11 = 0 then
                    nskip := nskip + 1;
                end if;

                v := s_data;
                s_ready <= '0';
                for t in 1 to nskip loop
                    wait until falling_edge(clk);
                    assert s_valid = '1' report "Output not valid";
                    assert s_data = v report "Output changed while not ready";
                end loop;
                s_ready <= '1';
            end if;

            -- Go to next cycle.
            wait until falling_edge(clk);

        end loop;

        -- Re-seed generator.
        report "Re-seed generator";
        s_reseed    <= '1';
        s_newseed   <= x"fedcba98";
        s_ready     <= '0';
        wait until falling_edge(clk);
        s_reseed    <= '0';
        s_newseed   <= (others => '0');

        -- Give generator time to complete initialization.
        for i in 0 to 4*624 loop
            assert s_valid = '0' report "Generator indicates VALID too early";
            wait until falling_edge(clk);
            s_ready     <= '1';
        end loop;

        -- Produce numbers
        for i in 0 to 999 loop

            -- Check that output is valid.
            assert s_valid = '1' report "Output not VALID";

            -- Write output to file.
            write(lin, "0x" & to_hex_string(s_data));
            writeline(outf2, lin);

            -- Sometimes skip cycles.
            if i mod 5 = 2 then
                nskip := 1;
                if i mod 3 = 0 then
                    nskip := nskip + 1;
                end if;
                if i mod 11 = 0 then
                    nskip := nskip + 1;
                end if;

                v := s_data;
                s_ready <= '0';
                for t in 1 to nskip loop
                    wait until falling_edge(clk);
                    assert s_valid = '1' report "Output not valid";
                    assert s_data = v report "Output changed while not ready";
                end loop;
                s_ready <= '1';
            end if;

            -- Go to next cycle.
            wait until falling_edge(clk);

        end loop;

        -- Re-seed generator.
        report "Re-seed generator";
        s_reseed    <= '1';
        s_newseed   <= x"0f5a3c57";
        s_ready     <= '0';
        wait until falling_edge(clk);
        s_reseed    <= '0';
        s_newseed   <= (others => '0');

        -- Give generator more than enough time to complete initialization.
        for i in 0 to 4*624 + 500 loop
            wait until falling_edge(clk);
        end loop;

        s_ready     <= '1';

        -- Produce numbers
        for i in 0 to 999 loop

            -- Check that output is valid.
            assert s_valid = '1' report "Output not VALID";

            -- Write output to file.
            write(lin, "0x" & to_hex_string(s_data));
            writeline(outf3, lin);

            -- Sometimes skip cycles.
            if i mod 5 = 2 then
                nskip := 1;
                if i mod 3 = 0 then
                    nskip := nskip + 1;
                end if;
                if i mod 11 = 0 then
                    nskip := nskip + 1;
                end if;

                v := s_data;
                s_ready <= '0';
                for t in 1 to nskip loop
                    wait until falling_edge(clk);
                    assert s_valid = '1' report "Output not valid";
                    assert s_data = v report "Output changed while not ready";
                end loop;
                s_ready <= '1';
            end if;

            -- Go to next cycle.
            wait until falling_edge(clk);

        end loop;

         -- End simulation.
        report "End testbench";

        clock_active    <= false;
        wait;

    end process;

end architecture;
