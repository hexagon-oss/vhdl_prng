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
#include <stdint.h>


/*  ========== BEGIN of reference implementation of xoroshiro128+ ==========
 *  Source: http://xoroshiro.di.unimi.it/
 */

/*  Written in 2016 by David Blackman and Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See <http://creativecommons.org/publicdomain/zero/1.0/>. */

int64_t s[2];

static inline uint64_t rotl(const uint64_t x, int k) {
    return (x << k) | (x >> (64 - k));
}

uint64_t next(void) {
    const uint64_t s0 = s[0];
    uint64_t s1 = s[1];
    const uint64_t result = s0 + s1;

    s1 ^= s0;
    s[0] = rotl(s0, 55) ^ s1 ^ (s1 << 14); // a, b
    s[1] = rotl(s1, 36); // c

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
        fprintf(stderr, "Usage: ref_xoroshiro SEED0 SEED1 NUMVALUE\n");
        fprintf(stderr, "    SEED0     seed value in range 0 .. (2**64-1)\n");
        fprintf(stderr, "    SEED1     seed value in range 0 .. (2**64-1)\n");
        fprintf(stderr, "    NUMVALUE  number of values to get from generator\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Example: ref_xoroshiro 0x3141592653589793 "
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

