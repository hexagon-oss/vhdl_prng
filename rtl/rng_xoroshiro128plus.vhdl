--
--  Pseudo Random Number Generator "xoroshiro128+".
--
--  Author: Joris van Rantwijk <joris@jorisvr.nl>
--
--  This is a 64-bit random number generator in synthesizable VHDL.
--  The generator can produce 64 new random bits on every clock cycle.
--
--  The algorithm "xoroshiro128+" is by David Blackman and Sebastiano Vigna.
--  See also http://xoroshiro.di.unimi.it/
--
--  The generator requires a 128-bit seed value, not equal to zero.
--  A default seed must be supplied at compile time and will be used
--  to initialize the generator at reset. The generator also supports
--  re-seeding at run time.
--
--  After reset and after re-seeding, at least one clock cycle is needed
--  before valid random data appears on the output.
--
--  NOTE: This is not a cryptographic random number generator.
--
--  NOTE: The least significant output bit is less random than
--        all other output bits.
--

--
--  Copyright (C) 2016 Joris van Rantwijk
--
--  This code is free software; you can redistribute it and/or
--  modify it under the terms of the GNU Lesser General Public
--  License as published by the Free Software Foundation; either
--  version 2.1 of the License, or (at your option) any later version.
--
--  See <https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity rng_xoroshiro128plus is

    generic (
        -- Default seed value.
        init_seed:  std_logic_vector(127 downto 0) );

    port (

        -- Clock, rising edge active.
        clk:        in  std_logic;

        -- Synchronous reset, active high.
        rst:        in  std_logic;

        -- High to request re-seeding of the generator.
        reseed:     in  std_logic;

        -- New seed value (must be valid when reseed = '1').
        newseed:    in  std_logic_vector(127 downto 0);

        -- High when the user accepts the current random data word
        -- and requests new random data for the next clock cycle.
        out_ready:  in  std_logic;

        -- High when valid random data is available on the output.
        -- This signal is low during the first clock cycle after reset and
        -- after re-seeding, and high in all other cases.
        out_valid:  out std_logic;

        -- Random output data (valid when out_valid = '1').
        -- A new random word appears after every rising clock edge
        -- where out_ready = '1'.
        out_data:   out std_logic_vector(63 downto 0) );

end entity;


architecture xoroshiro128plus_arch of rng_xoroshiro128plus is

    -- Internal state of RNG.
    signal reg_state_s0:    std_logic_vector(63 downto 0) := init_seed(63 downto 0);
    signal reg_state_s1:    std_logic_vector(63 downto 0) := init_seed(127 downto 64);

    -- Output register.
    signal reg_valid:       std_logic;
    signal reg_output:      std_logic_vector(63 downto 0) := (others => '0');

    -- Shift left.
    function shiftl(x: std_logic_vector; b: integer)
        return std_logic_vector
    is
        constant n: integer := x'length;
        variable y: std_logic_vector(n-1 downto 0);
    begin
        y(n-1 downto b) := x(x'high-b downto x'low);
        y(b-1 downto 0) := (others => '0');
        return y;
    end function;

    -- Rotate left.
    function rotl(x: std_logic_vector; b: integer)
        return std_logic_vector
    is
        constant n: integer := x'length;
        variable y: std_logic_vector(n-1 downto 0);
    begin
        y(n-1 downto b) := x(x'high-b downto x'low);
        y(b-1 downto 0) := x(x'high downto x'high-b+1);
        return y;
    end function;

begin

    -- Drive output signal.
    out_valid   <= reg_valid;
    out_data    <= reg_output;

    -- Synchronous process.
    process (clk) is
    begin
        if rising_edge(clk) then

            if out_ready = '1' or reg_valid = '0' then

                -- Prepare output word.
                reg_valid       <= '1';
                reg_output      <= std_logic_vector(unsigned(reg_state_s0) +
                                                    unsigned(reg_state_s1));

                -- Update internal state.
                reg_state_s0    <= reg_state_s0 xor
                                   reg_state_s1 xor
                                   shiftl(reg_state_s0, 14) xor
                                   shiftl(reg_state_s1, 14) xor
                                   rotl(reg_state_s0, 55);

                reg_state_s1    <= rotl(reg_state_s0, 36) xor
                                   rotl(reg_state_s1, 36);

            end if;

            -- Re-seed function.
            if reseed = '1' then
                reg_state_s0    <= newseed(63 downto 0);
                reg_state_s1    <= newseed(127 downto 64);
                reg_valid       <= '0';
            end if;

            -- Synchronous reset.
            if rst = '1' then
                reg_state_s0    <= init_seed(63 downto 0);
                reg_state_s1    <= init_seed(127 downto 64);
                reg_valid       <= '0';
                reg_output      <= (others => '0');
            end if;

        end if;
    end process;

end architecture;

