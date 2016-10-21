--
--  Pseudo Random Number Generator based on Mersenne Twister MT19937.
--
--  Author: Joris van Rantwijk <joris@jorisvr.nl>
--
--  This is a 32-bit random number generator in synthesizable VHDL.
--  The generator produces 32 new random bits on every (enabled) clock cycle.
--
--  See also M. Matsumoto, T. Nishimura, "Mersenne Twister:
--  a 623-dimensionally equidistributed uniform pseudorandom number generator",
--  ACM TOMACS, vol. 8, no. 1, 1998.
--
--  The generator requires a 32-bit seed value.
--  A default seed must be supplied at compile time and will be used
--  to initialize the generator at reset. The generator also supports
--  re-seeded at run time.
--
--  After reset, and after re-seeding, the generator needs 625 clock
--  cycles to initialize its internal state. During this time, the generator
--  is unable to provide correct output.
--
--  NOTE: This is not a cryptographic random number generator.
--

-- TODO : Multiplication in reseeding severely limits the maximum frequency
--        for this design.
--        Add pipelining and increase the number of clock cycles for reseeding.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity rng_mt19937 is

    generic (
        -- Default seed value.
        init_seed:  std_logic_vector(31 downto 0) );

    port (

        -- Clock, rising edge active.
        clk:        in  std_logic;

        -- Synchronous reset, active high.
        rst:        in  std_logic;

        -- High to generate new output value.
        enable:     in  std_logic;

        -- High to re-seed the generator (works regardless of enable signal).
        reseed:     in  std_logic;

        -- New seed value (must be valid when reseed = '1').
        newseed:    in  std_logic_vector(31 downto 0);

        -- Output value.
        -- A new value appears on every rising clock edge where enable = '1'.
        output:     out std_logic_vector(31 downto 0);

        -- High while re-seeding (normal function not available).
        busy:       out std_logic );

end entity;


architecture rng_mt19937_arch of rng_mt19937 is

    -- Constants.
    constant const_a: std_logic_vector(31 downto 0) := x"9908b0df";
    constant const_b: std_logic_vector(31 downto 0) := x"9d2c5680";
    constant const_c: std_logic_vector(31 downto 0) := x"efc60000";
    constant const_f: natural                       := 1812433253;

    -- Block RAM for generator state.
    type mem_t is array(0 to 620) of std_logic_vector(31 downto 0);
    signal mem: mem_t;

    -- RAM access registers.
    signal reg_a_addr:      std_logic_vector(9 downto 0);
    signal reg_b_addr:      std_logic_vector(9 downto 0);
    signal reg_a_wdata:     std_logic_vector(31 downto 0);
    signal reg_a_rdata:     std_logic_vector(31 downto 0);
    signal reg_b_rdata:     std_logic_vector(31 downto 0);

    -- Internal registers.
    signal reg_enable:      std_logic;
    signal reg_reseeding1:  std_logic;
    signal reg_reseeding2:  std_logic;
    signal reg_a_wdata_p:   std_logic_vector(31 downto 0);
    signal reg_a_rdata_p:   std_logic_vector(31 downto 0);
    signal reg_reseed_cnt:  std_logic_vector(9 downto 0);

    -- Output register.
    signal reg_output:      std_logic_vector(31 downto 0) := (others => '0');
    signal reg_busy:        std_logic;

--    -- Multiply unsigned number with constant and discard overflowing bits.
--    function mulconst(x: unsigned)
--        return unsigned
--    is
--        variable t: unsigned(2*x'length-1 downto 0);
--    begin
--        t := x * const_f;
--        return t(x'length-1 downto 0);
--    end function;

    -- Multiply unsigned number with constant and discard overflowing bits.
    function mulconst(x: unsigned)
        return unsigned
    is
    begin
        return x
               + shift_left(x, 2)
               + shift_left(x, 5)
               + shift_left(x, 6)
               + shift_left(x, 8)
               + shift_left(x, 11)
               - shift_left(x, 15)
               + shift_left(x, 19)
               - shift_left(x, 26)
               - shift_left(x, 28)
               + shift_left(x, 31);
    end function;

begin

    -- Drive output signal.
    output      <= reg_output;
    busy        <= reg_busy;

    -- Main synchronous process.
    process (clk) is
        variable y: std_logic_vector(31 downto 0);
    begin
        if rising_edge(clk) then

            -- Update memory pointers.
            if reg_enable = '1' then

                if unsigned(reg_a_addr) = 620 then
                    reg_a_addr <= (others => '0');
                else
                    reg_a_addr <= std_logic_vector(unsigned(reg_a_addr) + 1);
                end if;

                if unsigned(reg_b_addr) = 620 then
                    reg_b_addr <= (others => '0');
                else
                    reg_b_addr <= std_logic_vector(unsigned(reg_b_addr) + 1);
                end if;

            end if;

            -- Keep previous values of registers.
            if reg_enable = '1' then
                reg_a_rdata_p   <= reg_a_rdata;
                reg_a_wdata_p   <= reg_a_wdata;
            end if;

            -- Update reseeding counter.
            reg_reseed_cnt  <= std_logic_vector(unsigned(reg_reseed_cnt) + 1);

            -- Determine end of reseeding.
            reg_busy        <= reg_reseeding2;
            reg_reseeding2  <= reg_reseeding1;
            if unsigned(reg_reseed_cnt) = 623 then
                reg_reseeding1  <= '0';
            end if;

            -- Enable state machine on next cycle
            --  a) during initialization, and
            --  b) on-demand for new output.
            reg_enable  <= reg_reseeding2 or enable;

            -- Update internal RNG state.
            if reg_enable = '1' then

                if reg_reseeding1 = '1' then

                    -- Continue re-seeding loop.
                    y := reg_a_wdata;
                    y(1 downto 0) := y(1 downto 0) xor y(31 downto 30);
                    reg_a_wdata <= std_logic_vector(
                                     mulconst(unsigned(y)) +
                                     unsigned(reg_reseed_cnt) );

                else

                    -- Normal operation.
                    -- Perform one step of the "twist" function.

                    y := reg_a_rdata_p(31 downto 31) &
                         reg_a_rdata(30 downto 0);

                    if y(0) = '1' then
                        y := "0" & y(31 downto 1);
                        y := y xor const_a;
                    else
                        y := "0" & y(31 downto 1);
                    end if;

                    reg_a_wdata_p <= reg_a_wdata;
                    reg_a_wdata <= reg_b_rdata xor y;

                end if;
            end if;

            -- Produce output value (when enabled).
            if enable = '1' then

                if reg_enable = '1' then
                    y := reg_a_wdata;
                else
                    y := reg_a_wdata_p;
                end if;

                y(20 downto 0)  := y(20 downto 0) xor y(31 downto 11);
                y(31 downto 7)  := y(31 downto 7) xor
                                   (y(24 downto 0) and const_b(31 downto 7));
                y(31 downto 15) := y(31 downto 15) xor
                                   (y(16 downto 0) and const_c(31 downto 15));
                y(13 downto 0)  := y(13 downto 0) xor y(31 downto 18);

                reg_output  <= y;

            end if;

            -- Start re-seeding.
            if reseed = '1' then
                reg_reseeding1  <= '1';
                reg_reseeding2  <= '1';
                reg_reseed_cnt  <= std_logic_vector(to_unsigned(1, 10));
                reg_enable      <= '1';
                reg_a_wdata     <= newseed;
                reg_busy        <= '1';
            end if;

            -- Synchronous reset.
            if rst = '1' then
                reg_a_addr      <= std_logic_vector(to_unsigned(0, 10));
                reg_b_addr      <= std_logic_vector(to_unsigned(396, 10));
                reg_reseeding1  <= '1';
                reg_reseeding2  <= '1';
                reg_reseed_cnt  <= std_logic_vector(to_unsigned(1, 10));
                reg_enable      <= '1';
                reg_a_wdata     <= init_seed;
                reg_output      <= (others => '0');
                reg_busy        <= '1';
            end if;

        end if;
    end process;

    -- Synchronous process for block RAM.
    process (clk) is
    begin
        if rising_edge(clk) then
            if reg_enable = '1' then

                -- Read from port A.
                reg_a_rdata <= mem(to_integer(unsigned(reg_a_addr)));

                -- Read from port B.
                reg_b_rdata <= mem(to_integer(unsigned(reg_b_addr)));

                -- Write to port A.
                mem(to_integer(unsigned(reg_a_addr))) <= reg_a_wdata;

            end if;
        end if;
    end process;

end architecture;

