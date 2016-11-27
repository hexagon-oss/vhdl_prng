--
-- Test bench for PRNG Trivium.
--

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_trivium is
end entity;

architecture arch of tb_trivium is

    type output_vector is record
        pos:    natural;
        data:   std_logic_vector(511 downto 0);
    end record;

    type output_vectors is array (natural range <>) of output_vector;

    type test_vector is record
        key:    std_logic_vector(79 downto 0);
        iv:     std_logic_vector(79 downto 0);
        data:   output_vectors(0 to 3);
--        data:   array (0 to 3) of output_vector;
    end record;

    type test_vectors is array (natural range <>) of test_vector;

    constant testvec: test_vectors(0 to 1) := (
        0 => ( key  => x"0053A6F94C9FF24598EB",
               iv   => x"0D74DB42A91077DE45AC",
               data => ( ( pos => 0, data =>
                           x"F4CD954A717F26A7D6930830C4E7CF08" &
                           x"19F80E03F25F342C64ADC66ABA7F8A8E" &
                           x"6EAA49F23632AE3CD41A7BD290A0132F" &
                           x"81C6D4043B6E397D7388F3A03B5FE358" ),
                         ( pos => 65472, data =>
                           x"C04C24A6938C8AF8A491D5E481271E0E" &
                           x"601338F01067A86A795CA493AA4FF265" &
                           x"619B8D448B706B7C88EE8395FC79E5B5" &
                           x"1AB40245BBF7773AE67DF86FCFB71F30" ),
                         ( pos => 65536, data =>
                           x"011A0D7EC32FA102C66C164CFCB189AE" &
                           x"D9F6982E8C7370A6A37414781192CEB1" &
                           x"55C534C1C8C9E53FDEADF2D3D0577DAD" &
                           x"3A8EB2F6E5265F1E831C86844670BC69" ),
                         ( pos => 131008, data =>
                           x"48107374A9CE3AAF78221AE77789247C" &
                           x"F6896A249ED75DCE0CF2D30EB9D889A0" &
                           x"C61C9F480E5C07381DED9FAB2AD54333" &
                           x"E82C89BA92E6E47FD828F1A66A8656E0" ))),
        1 => ( key  => x"80000000000000000000",
               iv   => x"00000000000000000000",
               data => ( ( pos => 0, data =>
                           x"38EB86FF730D7A9CAF8DF13A4420540D" &
                           x"BB7B651464C87501552041C249F29A64" &
                           x"D2FBF515610921EBE06C8F92CECF7F80" &
                           x"98FF20CCCC6A62B97BE8EF7454FC80F9" ),
                         ( pos => 192, data =>
                           x"EAF2625D411F61E41F6BAEEDDD5FE202" &
                           x"600BD472F6C9CD1E9134A745D900EF6C" &
                           x"023E4486538F09930CFD37157C0EB57C" &
                           x"3EF6C954C42E707D52B743AD83CFF297" ),
                         ( pos => 256, data =>
                           x"9A203CF7B2F3F09C43D188AA13A5A202" &
                           x"1EE998C42F777E9B67C3FA221A0AA1B0" &
                           x"41AA9E86BC2F5C52AFF11F7D9EE480CB" &
                           x"1187B20EB46D582743A52D7CD080A24A" ),
                         ( pos => 448, data =>
                           x"EBF14772061C210843C18CEA2D2A275A" &
                           x"E02FCB18E5D7942455FF77524E8A4CA5" &
                           x"1E369A847D1AEEFB9002FCD02342983C" &
                           x"EAFA9D487CC2032B10192CD416310FA4" )))
    );

    signal clk:             std_logic;
    signal clock_active:    boolean := false;

    signal x1_rst:          std_logic;
    signal x1_reseed:       std_logic;
    signal x1_newkey:       std_logic_vector(79 downto 0);
    signal x1_newiv:        std_logic_vector(79 downto 0);
    signal x1_out_ready:    std_logic;
    signal x1_out_valid:    std_logic;
    signal x1_out_data:     std_logic_vector(0 downto 0);

    signal x8_rst:          std_logic;
    signal x8_reseed:       std_logic;
    signal x8_newkey:       std_logic_vector(79 downto 0);
    signal x8_newiv:        std_logic_vector(79 downto 0);
    signal x8_out_ready:    std_logic;
    signal x8_out_valid:    std_logic;
    signal x8_out_data:     std_logic_vector(7 downto 0);

    signal x64_rst:         std_logic;
    signal x64_reseed:      std_logic;
    signal x64_newkey:      std_logic_vector(79 downto 0);
    signal x64_newiv:       std_logic_vector(79 downto 0);
    signal x64_out_ready:   std_logic;
    signal x64_out_valid:   std_logic;
    signal x64_out_data:    std_logic_vector(63 downto 0);

    -- Convert bit vector to hexadecimal string.
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

    -- Reverse order of 8-bit groups within long bit vector.
    function flipbits(x: std_logic_vector) return std_logic_vector is
        variable y: std_logic_vector(x'length-1 downto 0);
    begin
        for p in 0 to x'length / 8 - 1 loop
            y(p*8+7 downto p*8) := x(x'high-p*8 downto x'high-p*8-7);
        end loop;
        return y;
    end function;

    -- Force interpretation of string literal.
    function force_str(s: string) return string is
    begin
        return s;
    end function;

    -- Test one of the instances of the RNG.
    procedure test_inst(signal s_rst:       out std_logic;
                        signal s_reseed:    out std_logic;
                        signal s_newkey:    out std_logic_vector(79 downto 0);
                        signal s_newiv:     out std_logic_vector(79 downto 0);
                        signal s_ready:     out std_logic;
                        signal s_valid:     in  std_logic;
                        signal s_data:      in  std_logic_vector)
    is
        constant nbit: natural := s_data'length;
        constant init_duration: natural := 4 * 288 / nbit;
        variable lin: line;
        variable p: natural := 0;
        variable bitpos: natural;
        variable vk: natural;
        variable w: std_logic_vector(511 downto 0);
        variable wp: natural;
    begin
        -- Initialize inputs.
        s_reseed    <= '0';
        s_newkey    <= (others => '0');
        s_newiv     <= (others => '0');
        s_ready     <= '0';

        -- End reset.
        wait until falling_edge(clk);
        s_rst       <= '0';

        -- Loop over test vectors.
        for k in testvec'range loop

            write(lin, force_str("key         = "));
            write(lin, to_hex_string(testvec(k).key));
            writeline(output, lin);
            write(lin, force_str("iv          = "));
            write(lin, to_hex_string(testvec(k).iv));
            writeline(output, lin);

            -- Reseed generator, except for first test vector.
            -- First test vector runs on initial seed.
            if k /= 0 then
                s_reseed    <= '1';
                s_newkey    <= flipbits(testvec(k).key);
                s_newiv     <= flipbits(testvec(k).iv);
                wait until falling_edge(clk);
                s_reseed    <= '0';
                s_newkey    <= (others => '0');
                s_newiv     <= (others => '0');
            end if;
            
            -- Give generator time to complete initialization.
            for i in 0 to init_duration loop
                assert s_valid = '0'
                    report "Generator indicates VALID too early";
                if (p mod 3 = 0) or (p mod 5 = 0) or (p mod 17 = 0) then
                    s_ready <= '0';
                else
                    s_ready <= '1';
                end if;
                wait until falling_edge(clk);
                p := p + 1;
            end loop;

            -- Start generating random bits.
            bitpos := 0;

            -- Start looping over output vectors.
            vk := testvec(k).data'low;

            while vk <= testvec(k).data'high loop

                -- Generate a block of bits.
                assert s_valid = '1' report "Output not VALID";

                if (p mod 3 = 0) or (p mod 5 = 0) or (p mod 17 = 0) then
                    -- Skipping this clock cycle.
                    s_ready <= '0';
                else
                    -- Consuming data this clock cycle.
                    s_ready <= '1';

                    if bitpos >= testvec(k).data(vk).pos * 8 then
                        -- Store bits in block.
                        wp := bitpos - testvec(k).data(vk).pos * 8;
                        assert wp = 0 or wp >= nbit
                            report "Invalid test vector offset";
                        assert wp + nbit <= w'length
                            report "Invalid test vector offset";
                        w(wp+nbit-1 downto wp) := s_data;
                    end if;

                    bitpos := bitpos + nbit;
                end if;

                wait until falling_edge(clk);
                p := p + 1;

                if bitpos = testvec(k).data(vk).pos * 8 + w'length then
                    -- Reached end of current output vector.

                    -- Dump output data to screen.
                    write(lin, force_str("out["));
                    write(lin, testvec(k).data(vk).pos, right, 6);
                    write(lin, force_str("] = "));
                    write(lin, to_hex_string(flipbits( w(127 downto 0))));
                    writeline(output, lin);
                    for tk in 1 to w'length / 128 - 1 loop
                        write(lin, force_str("              "));
                        write(lin, to_hex_string(flipbits(
                                       w(128*tk+127 downto 128*tk))));
                        writeline(output, lin);
                    end loop;

                    -- Check against expected output vector.
                    assert w = flipbits(testvec(k).data(vk).data)
                        report "Unexpected output from RNG";

                    -- Go to next output vector.
                    vk := vk + 1;
                end if;

            end loop;

            -- Go to next test vector.
            writeline(output, lin);
        end loop;

        -- Put instance back in reset.
        s_rst       <= '1';

    end procedure;

begin

    -- Instantiate PRNG with 1-bit output.
    inst_x1: entity work.rng_trivium
        generic map (
            num_bits    => 1,
            init_key    => x"eb9845f29f4cf9a65300",
            init_iv     => x"ac45de7710a942db740d" )
        port map (
            clk         => clk,
            rst         => x1_rst,
            reseed      => x1_reseed,
            newkey      => x1_newkey,
            newiv       => x1_newiv,
            out_ready   => x1_out_ready,
            out_valid   => x1_out_valid,
            out_data    => x1_out_data );
            
    -- Instantiate PRNG with 8-bit output.
    inst_x8: entity work.rng_trivium
        generic map (
            num_bits    => 8,
            init_key    => x"0053A6F94C9FF24598EB",
            init_iv     => x"0D74DB42A91077DE45AC" )
        port map (
            clk         => clk,
            rst         => x8_rst,
            reseed      => x8_reseed,
            newkey      => x8_newkey,
            newiv       => x8_newiv,
            out_ready   => x8_out_ready,
            out_valid   => x8_out_valid,
            out_data    => x8_out_data );
            
    -- Instantiate PRNG with 64-bit output.
    inst_x64: entity work.rng_trivium
        generic map (
            num_bits    => 64,
            init_key    => x"eb9845f29f4cf9a65300",
            init_iv     => x"ac45de7710a942db740d" )
        port map (
            clk         => clk,
            rst         => x64_rst,
            reseed      => x64_reseed,
            newkey      => x64_newkey,
            newiv       => x64_newiv,
            out_ready   => x64_out_ready,
            out_valid   => x64_out_valid,
            out_data    => x64_out_data );

    -- Generate clock.
    clk <= (not clk) after 10 ns when clock_active else '0';

    -- Main simulation process.
    process is
    begin

        report "Start test bench";

        -- Reset all instances.
        x1_rst      <= '1';
        x8_rst      <= '1';
        x64_rst     <= '1';

        -- Start clock.
        clock_active    <= true;
        wait for 30 ns;

        -- Test 1-bit instance.
        report "Test 1-bit generator";
        test_inst(x1_rst, x1_reseed, x1_newkey, x1_newiv,
                  x1_out_ready, x1_out_valid, x1_out_data);

        -- Test 8-bit instance.
        report "Test 8-bit generator";
        test_inst(x8_rst, x8_reseed, x8_newkey, x8_newiv,
                  x8_out_ready, x8_out_valid, x8_out_data);

        -- Test 64-bit instance.
        report "Test 64-bit generator";
        test_inst(x64_rst, x64_reseed, x64_newkey, x64_newiv,
                  x64_out_ready, x64_out_valid, x64_out_data);

         -- End simulation.
        report "End testbench";

        clock_active    <= false;
        wait;

    end process;

end architecture;
