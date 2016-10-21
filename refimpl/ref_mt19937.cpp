/*
 * Reference implementation of Mersenne Twister MT19937 in C++11.
 *
 * Written in 2016 by Joris van Rantwijk <joris@jorisvr.nl>
 *
 * To the extent possible under law, the author(s) have dedicated all copyright
 * and related and neighboring rights to this software to the public domain
 * worldwide. This software is distributed without any warranty.
 *
 * See <http://creativecommons.org/publicdomain/zero/1.0/>
 */

#include <cstdlib>
#include <cstdio>
#include <random>

using namespace std;


int main(int argc, const char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "Reference implementation of Mersenne Twister MT19937\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Usage: ref_mt19937 SEED NUMVALUE\n");
        fprintf(stderr, "    SEED      seed value in range 0 .. (2**31-1)\n");
        fprintf(stderr, "    NUMVALUE  number of values to get from generator\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Example: ref_mt19937 0x31415926 100\n");
        exit(1);
    }

    char *p;
    unsigned long seed = strtoul(argv[1], &p, 0);
    if (p == argv[1] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for SEED0\n");
        exit(1);
    }

    unsigned long numval = strtoul(argv[2], &p, 0);
    if (p == argv[3] || *p != '\0') {
        fprintf(stderr, "ERROR: Invalid value for NUMVALUE\n");
        exit(1);
    }

    mt19937 rng(seed);

    for (unsigned long k = 0; k < numval; k++) {
        printf("0x%08lx\n", (unsigned long) rng());
    }

    return 0;
}

