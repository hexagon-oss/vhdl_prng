/*
 * Reference implementation of "Trivium" in C++11.
 *
 * Written in 2016 by Joris van Rantwijk <joris@jorisvr.nl> 
 *
 * To the extent possible under law, the author has dedicated all copyright
 * and related and neighboring rights to this software to the public domain
 * worldwide. This software is distributed without any warranty.
 *
 * See <http://creativecommons.org/publicdomain/zero/1.0/>
 *
 * NOTE: This is a very naive and slow implementation of Trivium,
 *       not suitable for practical use.
 */

#include <cstdio>
#include <bitset>

struct trivium_state {
    std::bitset<93>  s1;
    std::bitset<84>  s2;
    std::bitset<111> s3;
};

/*
 * Generate one random bit and update state.
 *
 * Returns: one random bit, value 0 or 1.
 */
unsigned int trivium_step(struct trivium_state *state)
{
    unsigned int t1 = state->s1[65] ^ state->s1[92];
    unsigned int t2 = state->s2[68] ^ state->s2[83];
    unsigned int t3 = state->s3[65] ^ state->s3[110];

    unsigned int z = t1 ^ t2 ^ t3;

    t1 ^= (state->s1[90] & state->s1[91]) ^ state->s2[77];
    t2 ^= (state->s2[81] & state->s2[82]) ^ state->s3[86];
    t3 ^= (state->s3[108] & state->s3[109]) ^ state->s1[68];

    state->s1 <<= 1;
    state->s1[0] = t3;
    state->s2 <<= 1;
    state->s2[0] = t1;
    state->s3 <<= 1;
    state->s3[0] = t2;

    return z;
}

/*
 * Initialize stream state with given key and IV.
 *
 *   key: pointer to 10 bytes of key data.
 *   iv:  pointer to 10 bytes of IV data.
 */
void trivium_init(struct trivium_state *state,
                  const unsigned char *key,
                  const unsigned char *iv)
{
    state->s1.reset();
    state->s2.reset();
    state->s3.reset();

    /*
     * NOTE: The least significant bit of the first byte of the key
     *       is mapped to s_80. The most significant bit of the last
     *       byte of the key is mapped to s_1.
     *
     *       This is the same as the phase-3, API-compliant version
     *       of Trivium as published on the ECRYPT website (but different
     *       from the original submitted code.)
     */
    for (unsigned int p = 0; p < 10; p++) {
        for (unsigned int k = 0; k < 8; k++) {
            state->s1[79-8*p-k] = ((key[p] >> k) & 1);
        }
    }

    /*
     * NOTE: The least significant bit of the first byte of the IV
     *       is mapped to s_173. The most significant bit of the last
     *       byte of the key is mapped to s_94.
     */
    for (unsigned int p = 0; p < 10; p++) {
        for (unsigned int k = 0; k < 8; k++) {
            state->s2[79-8*p-k] = ((iv[p] >> k) & 1);
        }
    }

    state->s3[108] = true;
    state->s3[109] = true;
    state->s3[110] = true;

    for (int i = 0; i < 4 * 288; i++) {
        trivium_step(state);
    }
}

/*
 * This is a small subset of the test vectors from
 * the ECRYPT stream cipher project.
 */
static const struct testvec {
    unsigned char key[10];
    unsigned char iv[10];
} testvecs[5] = {
    { { 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
      { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
    { { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
      { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
    { { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
      { 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
    { { 0x00, 0x53, 0xA6, 0xF9, 0x4C, 0x9F, 0xF2, 0x45, 0x98, 0xEB },
      { 0x0D, 0x74, 0xDB, 0x42, 0xA9, 0x10, 0x77, 0xDE, 0x45, 0xAC } },
    { { 0x05, 0x58, 0xAB, 0xFE, 0x51, 0xA4, 0xF7, 0x4A, 0x9D, 0xF0 },
      { 0x16, 0x7D, 0xE4, 0x4B, 0xB2, 0x19, 0x80, 0xE7, 0x4E, 0xB5 } }
};


int main(void)
{
    const unsigned int nvec = sizeof(testvecs) / sizeof(testvecs[0]);
    struct trivium_state state;

    for (unsigned int i = 0; i < nvec; i++) {

        printf("key         =");
        for (unsigned int p = 0; p < 10; p++)
            printf(" %02x", testvecs[i].key[p]);
        printf("\n");

        printf("iv          =");
        for (unsigned int p = 0; p < 10; p++)
            printf(" %02x", testvecs[i].iv[p]);
        printf("\n");

        trivium_init(&state, testvecs[i].key, testvecs[i].iv);

        unsigned int np = 0;
        for (unsigned int p = 0; p < 131072; p++) {

            // Generate 8 random bits.
            // Map first-generated bit to least significant bit within byte;
            // last-generated bit to most significant bit.
            unsigned int t = 0;
            for (unsigned int k = 0; k < 8; k++) {
                t = (t >> 1) | (trivium_step(&state) << 7);
            }

            // Write parts of the output to screen.
            if (p == 0 || p == 448 || p == 131008) {
                np = 64;
                printf("data+%-6d =", p);
            } else if (np > 0 && np % 16 == 0) {
                printf("             ");
            }
            if (np > 0) {
                printf(" %02x", t);
                np--;
                if (np % 16 == 0) {
                    printf("\n");
                }
            }
        }
        printf("\n");
    }

    return 0;
}

