
  Pseudo-Random Number Generators in VHDL
 =========================================

This library contains a number of pseudo-random number generators (PRNG)
in synthesizable VHDL code.

The PRNGs in this library are useful to generate noise in digital signal
processing and to generate random numbers for monte-carlo simulations or
for games.

The VHDL code is portable and should run on any FPGA/synthesis platform,
but the designs are somewhat optimized for Xilinx FPGAs.

These PRNGs are a good alternative to linear feedback shift registers (LFSR).
Although LFSRs are commonly used, their output exhibits strong correlations.
Furthermore, correctly generating multi-bit random words with LFSRs is tricky.

NOTE: This library is not designed for cryptographic applications
      (such as generating passwords, encryption keys).
      Most of the RNGs in this library are cryptographically weak.


  Xoshiro128++ RNG
  ----------------

Xoshiro128++ is a random number generator developed in 2019 by
David Blackman and Sebastiano Vigna. The Xoshiro construction is 
based on the Xorshift concept invented by George Marsaglia.

See also http://prng.di.unimi.it/

This RNG produces a sequence of 32-bit words. It passes all known
statistical tests and has a relatively long period (2**128 - 1).

The VHDL implementation produces 32 new random bits on every (enabled)
clock cycle. It is quite efficient in terms of FPGA resources, but it
requires two cascaded 32-bit adders which limits its speed.

Output word length: 32 bits
Seed length:        128 bits
Period:             2**128 - 1

FPGA resources:     general logic and two 32-bit adders
Synthesis results:  148 LUTs, 161 registers on Spartan-6
                    148 LUTs, 161 registers on Spartan-7
Timing results:     250 MHz on Spartan-6 LX45-3
                    200 MHz on Spartan-7 S25-1


  Xoroshiro128+ RNG
  -----------------

Xoroshiro128+ is an RNG algorithm developed in 2016 by David Blackman
and Sebastiano Vigna. The VHDL code matches an updated version of
the algorithm called "xoroshiro128+ 1.0", released in 2018.
The Xoroshiro algorithm is based on the Xorshift concept invented
by George Marsaglia.

See also http://prng.di.unimi.it/

This RNG passes many statistical tests, but the least significant
output bits are known to be not fully random and fail certain tests.
The generator has a long period (2**128 - 1) compared to a typical LFSR,
but much shorter than the Mersenne Twister.
The output is 1-dimensionally equidistributed.

The VHDL implementation produces 64 new random bits on every (enabled)
clock cycle. It is quite efficient in terms of FPGA resources, but it
does require a 64-bit adder.

Output word length: 64 bits
Seed length:        128 bits
Period:             2**128 - 1

FPGA resources:     general logic and 64-bit adder
Synthesis results:  198 LUTs, 193 registers on Spartan-6
Timing results:     333 MHz on Spartan-6 LX45-3


  Mersenne Twister RNG
  --------------------

The Mersenne Twister is an RNG algorithm developed in 1997 by
Makoto Matsumoto and Takuji Nishimura. This library implements
the most common variant of the algorithm, MT19937.

See also M. Matsumoto, T. Nishimura, "Mersenne Twister: a 623-dimensionally
equidistributed uniform pseudorandom number generator", ACM TOMACS, vol. 8,
no. 1, 1998.

This RNG is very popular in software applications. It is relatively fast,
passes many statistical tests and has an enormous period.

The VHDL implementation produces 32 new random bits on every (enabled)
clock cycle. It uses a RAM block, 32 bits wide, 1024 elements deep,
to store the RNG state.

The most demanding part of the implementation is the seeding procedure.
Seeding involves repeated multiplication by a 32-bit constant. This
multiplication is implemented as a hand-coded series of shifts and adds
when force_const_mul = true; the multiplication is left to the synthesizer
when force_const_mul = false. The hand-coded variant is much more efficient
on Xilinx Spartan-6, so the recommended setting is force_const_mul = true.

After reset and after each reseeding, the RNG needs 2496 clock cycles
to initialize its state. The RNG can not provide random data during this time.

Output word length: 32 bits
Seed length:        32 bits
Period:             2**19937 - 1

FPGA resources:     RAM block, 32 bits x 1024 elements
Synthesis results:  279 LUTs, 297 registers, 2x RAMB16 on Spartan-6
Timing results:     300 MHz on Spartan-6 LX45-3


  Trivium RNG
  -----------

Trivium is a stream cipher published in 2005 by Christophe De Canniere
and Bart Preneel as part of the eSTREAM project. 

See also C. De Canniere, B. Preneel, "Trivium Specifications",
http://www.ecrypt.eu.org/stream/p3ciphers/trivium/trivium_p3.pdf

See also the eSTREAM portfolio page for Trivium:
http://www.ecrypt.eu.org/stream/e2-trivium.html

This library uses the key stream of the Trivium cipher as a sequence
of random bits. The VHDL implementation produces up to 64 new random bits
on every (enabled) clock cycle. The number of bits per clock cycle is
configurade as a synthesis parameter.

This RNG passes all known statistical tests. However, little is known
about its period. The period depends on the seed value, and is believed
to be long (at least 2**80) for the vast majority of seed choices.

After reset and after each reseeding, the RNG must process 1152 bits
to initialize its state. This takes up to 1152 clock cycles, depending
on the configured number of bits per cycle. The RNG can not provide random
data during this time.

Output word length: configurable from 1 to 64 bits (must be power-of-2)
Seed length:        80 bits key + 80 bits IV
Period:             unknown, depends on seed

FPGA resources:     only general logic (AND, XOR ports, registers)
Synthesis results:  202 LUTs, 332 registers on Spartan-6 (32 bits output)
                    145 LUTs, 332 registers on Spartan-7 (32 bits output)
Timing results:     380 MHz on Spartan-6 LX45-3 (32 bits output)
                    440 MHz on Spartan-7 S25-1 (32 bits output)


  Code organization
  -----------------

 rtl/                             Synthesizable VHDL code
 rtl/rng_xoshiro128plusplus.vhdl  Implementation of Xoshiro128++ RNG
 rtl/rng_xoroshiro128plus.vhdl    Implementation of Xoroshiro128+ RNG
 rtl/rng_mt19937.vhdl             Implementation of Mersenne Twister RNG
 rtl/rng_trivium.vhdl             Implementation of Trivium RNG

 sim/                             Test benches
 sim/Makefile                     Makefile for building test benches with GHDL
 sim/tb_xoshiro128plusplus.vhdl   Test bench for Xoshiro128++ RNG
 sim/tb_xoroshiro128plus.vhdl     Test bench for Xoroshiro128+ RNG
 sim/tb_mt19937.vhdl              Test bench for Mersenne Twister RNG
 sim/tb_trivium.vhdl              Test bench for Trivium RNG

 refimpl/                         Reference software implementations of RNGs

 synth/                           Top-level wrappers for synthesis testruns


  License
  -------

Copyright (C) 2016-2020 Joris van Rantwijk

This VHDL library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
s published by the Free Software Foundation; either version 2.1
of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, see
  <https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>

This package contains a few support files which are distributed
under Creative Commons CC0. This is explicitly and clearly marked
in the files to which it applies.

--
