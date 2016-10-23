
library ieee;
use ieee.std_logic_1164.all;

entity top is
    port (
        clk :   in  std_logic;
        rst :   in  std_logic;
        ready:  in  std_logic;
        valid:  out std_logic;
        data:   out std_logic_vector(31 downto 0) );
end top;

architecture arch of top is
begin

    inst_prng: entity work.rng_mt19937
        generic map (
            init_seed => x"31415926",
            force_const_mul => true )
        port map (
            clk       => clk,
            rst       => rst,
            reseed    => '0',
            newseed   => (others => '0'),
            out_ready => ready,
            out_valid => valid,
            out_data  => data );

end arch;

