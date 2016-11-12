
library ieee;
use ieee.std_logic_1164.all;

entity topxs is
    port (
        clk :   in  std_logic;
        rst :   in  std_logic;
        ready:  in  std_logic;
        valid:  out std_logic;
        data:   out std_logic_vector(63 downto 0) );
end topxs;

architecture arch of topxs is
begin

    inst_prng: entity work.rng_xoroshiro128plus
        generic map (
            init_seed => x"0123456789abcdef3141592653589793" )
        port map (
            clk       => clk,
            rst       => rst,
            reseed    => '0',
            newseed   => (others => '0'),
            out_ready => ready,
            out_valid => valid,
            out_data  => data );

end arch;

