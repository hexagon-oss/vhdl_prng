
library ieee;
use ieee.std_logic_1164.all;

entity toptriv is
    port (
        clk :   in  std_logic;
        rst :   in  std_logic;
        ready:  in  std_logic;
        valid:  out std_logic;
        data:   out std_logic_vector(31 downto 0) );
end toptriv;

architecture arch of toptriv is
begin

    inst_prng: entity work.rng_trivium
        generic map (
            num_bits  => 32,
            init_key  => x"31415926535897932384",
            init_iv   => x"0123456789abcdefa50f" )
        port map (
            clk       => clk,
            rst       => rst,
            reseed    => '0',
            newkey    => (others => '0'),
            newiv     => (others => '0'),
            out_ready => ready,
            out_valid => valid,
            out_data  => data );

end arch;

