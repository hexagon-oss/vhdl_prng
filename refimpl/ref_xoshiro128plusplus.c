/*
 * Reference implementation of "xoshiro128++" in C.
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


/*  ========== BEGIN of reference implementation of xoshiro128++ ==========
 *  Source: http://prng.di.unimi.it/
 */

/*  Written in 2019 by David Blackman and Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See <http://creativecommons.org/publicdomain/zero/1.0/>. */

#include <stdint.h>

/* This is xoshiro128++ 1.0, one of our 32-bit all-purpose, rock-solid
   generators. It has excellent speed, a state size (128 bits) that is
   large enough for mild parallelism, and it passes all tests we are aware
   of.

   For generating just single-precision (i.e., 32-bit) floating-point
   numbers, xoshiro128+ is even faster.

   The state must be seeded so that it is not everywhere zero. */


static inline uint32_t rotl(const uint32_t x, int k) {
	return (x << k) | (x >> (32 - k));
}


static uint32_t s[4];

uint32_t next(void) {
	const uint32_t result = rotl(s[0] + s[3], 7) + s[0];

	const uint32_t t = s[1] << 9;

	s[2] ^= s[0];
	s[3] ^= s[1];
	s[1] ^= s[2];
	s[0] ^= s[3];

	s[2] ^= t;

	s[3] = rotl(s[3], 11);

	return result;
}

/*  ========== END of reference implementation of xoshiro128++ ========== */


int main(int argc, const char **argv)
{
    char *p;
    unsigned long numval;
    unsigned long k;
    unsigned long long seed_tmp;

    if (argc != 4) {
        fprintf(stderr, "Reference implementation of RNG xoshiro128++\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Usage: ref_xoshiro128plusplus SEED0 SEED1 NVALUE\n");
        fprintf(stderr, "    SEEDn     seed value in range 0 .. (2**64-1)\n");
        fprintf(stderr, "    NVALUE    number of values to get from generator\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Example: ref_xoshiro128plusplus 0x3141592653589793 "
                        "0x0123456789abcdef 100\n");
        exit(1);
    }

    seed_tmp = strtoull(argv[1], &p, 0);
    if (p == argv[1] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for SEED0\n");
        exit(1);
    }

    s[0] = (uint32_t)seed_tmp;
    s[1] = (uint32_t)(seed_tmp >> 32);

    seed_tmp = strtoull(argv[2], &p, 0);
    if (p == argv[2] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for SEED1\n");
        exit(1);
    }

    s[2] = (uint32_t)seed_tmp;
    s[3] = (uint32_t)(seed_tmp >> 32);

    numval = strtoul(argv[3], &p, 0);
    if (p == argv[3] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for NVALUE\n");
        exit(1);
    }

    for (k = 0; k < numval; k++) {
        printf("0x%08lx\n", (unsigned long) next());
    }

    return 0;
}

