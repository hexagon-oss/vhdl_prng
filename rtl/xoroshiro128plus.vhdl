--
--  Pseudo Random Number Generator "xoroshiro128+".
--
--  Author: Joris van Rantwijk <joris@jorisvr.nl>
--
--  This is a 64-bit random number generator in synthesizable VHDL.
--  The generator produces 64 new random bits on every (enabled) clock cycle.
--
--  The algorithm "xoroshiro128+" is by David Blackman and Sebastiano Vigna.
--  See also http://xoroshiro.di.unimi.it/
--
--  The generator requires a 128-bit seed value, not equal to zero.
--  A default seed must be supplied at compile time and will be used
--  to initialize the generator at reset. The generator also supports
--  re-seeding at run time.
--
--  After reset, at least one enabled clock cycle is needed before
--  a random number appears on the output.
--
--  NOTE: This is not a cryptographic random number generator.
--
--  NOTE: The least significant output bit is less random than
--        all other output bits.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity xoroshiro128plus is

    generic (
        -- Default seed value.
        init_seed:  std_logic_vector(127 downto 0) );

    port (

        -- Clock, rising edge active.
        clk:        in  std_logic;

        -- Synchronous reset, active high.
        rst:        in  std_logic;

        -- Clock enable, active high.
        enable:     in  std_logic;

        -- High to re-seed the generator (requires enable = '1').
        reseed:     in  std_logic;

        -- New seed value (must be valid when reseed = '1').
        newseed:    in  std_logic_vector(127 downto 0);

        -- Output value.
        -- A new value appears on every rising clock edge where enable = '1'.
        output:     out std_logic_vector(63 downto 0) );

end entity;


architecture xoroshiro128plus_arch of xoroshiro128plus is

    -- Internal state of RNG.
    signal reg_state_s0:    std_logic_vector(63 downto 0) := init_seed(63 downto 0);
    signal reg_state_s1:    std_logic_vector(63 downto 0) := init_seed(127 downto 64);

    -- Output register.
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
    output      <= reg_output;

    -- Synchronous process.
    process (clk) is
    begin
        if rising_edge(clk) then

            if enable = '1' then

                -- Prepare output word.
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

                -- Re-seed function.
                if reseed = '1' then
                    reg_state_s0    <= newseed(63 downto 0);
                    reg_state_s1    <= newseed(127 downto 64);
                end if;

            end if;

            -- Synchronous reset.
            if rst = '1' then
                reg_state_s0    <= init_seed(63 downto 0);
                reg_state_s1    <= init_seed(127 downto 64);
                reg_output      <= (others => '0');
            end if;

        end if;
    end process;

end architecture;

