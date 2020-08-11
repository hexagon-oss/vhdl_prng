/*
 * Reference implementation of "xoroshiro128+" in C.
 *
 * Algorithm code by David Blackman and Sebastiano Vigna <vigna@acm.org>
 * Main program wrapper by Joris van Rantwijk <joris@jorisvr.nl>
 *
 * To the extent possible under law, the author has dedicated all copyright
 * and related and neighboring rights to this software to the public domain
 * worldwide. This software is distributed without any warranty.
 *
 * See <http://creativecommons.org/publicdomain/zero/1.0/>
 */

#include <stdlib.h>
#include <stdio.h>


/*  ========== BEGIN of reference implementation of xoroshiro128+ ==========
 *  Source: http://prng.di.unimi.it/
 */

/*  Written in 2016-2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See <http://creativecommons.org/publicdomain/zero/1.0/>. */

#include <stdint.h>

/* This is xoroshiro128+ 1.0, our best and fastest small-state generator
   for floating-point numbers. We suggest to use its upper bits for
   floating-point generation, as it is slightly faster than
   xoroshiro128++/xoroshiro128**. It passes all tests we are aware of
   except for the four lower bits, which might fail linearity tests (and
   just those), so if low linear complexity is not considered an issue (as
   it is usually the case) it can be used to generate 64-bit outputs, too;
   moreover, this generator has a very mild Hamming-weight dependency
   making our test (http://prng.di.unimi.it/hwd.php) fail after 5 TB of
   output; we believe this slight bias cannot affect any application. If
   you are concerned, use xoroshiro128++, xoroshiro128** or xoshiro256+.

   We suggest to use a sign test to extract a random Boolean value, and
   right shifts to extract subsets of bits.

   The state must be seeded so that it is not everywhere zero. If you have
   a 64-bit seed, we suggest to seed a splitmix64 generator and use its
   output to fill s. 

   NOTE: the parameters (a=24, b=16, b=37) of this version give slightly
   better results in our test than the 2016 version (a=55, b=14, c=36).
*/

static inline uint64_t rotl(const uint64_t x, int k) {
	return (x << k) | (x >> (64 - k));
}


static uint64_t s[2];

uint64_t next(void) {
	const uint64_t s0 = s[0];
	uint64_t s1 = s[1];
	const uint64_t result = s0 + s1;

	s1 ^= s0;
	s[0] = rotl(s0, 24) ^ s1 ^ (s1 << 16); // a, b
	s[1] = rotl(s1, 37); // c

	return result;
}

/*  ========== END of reference implementation of xoroshiro128+ ========== */


int main(int argc, const char **argv)
{
    char *p;
    unsigned long numval;
    unsigned long k;

    if (argc != 4) {
        fprintf(stderr, "Reference implementation of RNG xoroshiro128+\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Usage: ref_xoroshiro128plus SEED0 SEED1 NUMVALUE\n");
        fprintf(stderr, "    SEED0     seed value in range 0 .. (2**64-1)\n");
        fprintf(stderr, "    SEED1     seed value in range 0 .. (2**64-1)\n");
        fprintf(stderr, "    NUMVALUE  number of values to get from generator\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Example: ref_xoroshiro128plus 0x3141592653589793 "
                        "0x0123456789abcdef 100\n");
        exit(1);
    }

    s[0] = strtoull(argv[1], &p, 0);
    if (p == argv[1] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for SEED0\n");
        exit(1);
    }

    s[1] = strtoull(argv[2], &p, 0);
    if (p == argv[2] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for SEED1\n");
        exit(1);
    }

    numval = strtoul(argv[3], &p, 0);
    if (p == argv[3] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for NUMVALUE\n");
        exit(1);
    }

    for (k = 0; k < numval; k++) {
        printf("0x%016llx\n", (unsigned long long) next());
    }

    return 0;
}

