
library ieee;
use ieee.std_logic_1164.all;

entity top_xoshiro128plusplus is
    port (
        clk :   in  std_logic;
        rst :   in  std_logic;
        ready:  in  std_logic;
        valid:  out std_logic;
        data:   out std_logic_vector(31 downto 0) );
end top_xoshiro128plusplus;

architecture arch of top_xoshiro128plusplus is
begin

    inst_prng: entity work.rng_xoshiro128plusplus
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

