/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# LibTomCrypt, modular cryptographic library -- Tom St Denis was ported to
# a C++ class-interface
# Tom St Denis, tomstdenis@gmail.com, http://libtom.org
#
# The C++ porter of this program may be contacted at leif@rdos.net
#
# sha256.cpp
# SHA256 hash class
#
########################################################################*/

#include <string.h>

#include "helper.h"
#include "sha256.h"

/* the K array */
static const unsigned long K[64] = {
    0x428a2f98UL, 0x71374491UL, 0xb5c0fbcfUL, 0xe9b5dba5UL, 0x3956c25bUL,
    0x59f111f1UL, 0x923f82a4UL, 0xab1c5ed5UL, 0xd807aa98UL, 0x12835b01UL,
    0x243185beUL, 0x550c7dc3UL, 0x72be5d74UL, 0x80deb1feUL, 0x9bdc06a7UL,
    0xc19bf174UL, 0xe49b69c1UL, 0xefbe4786UL, 0x0fc19dc6UL, 0x240ca1ccUL,
    0x2de92c6fUL, 0x4a7484aaUL, 0x5cb0a9dcUL, 0x76f988daUL, 0x983e5152UL,
    0xa831c66dUL, 0xb00327c8UL, 0xbf597fc7UL, 0xc6e00bf3UL, 0xd5a79147UL,
    0x06ca6351UL, 0x14292967UL, 0x27b70a85UL, 0x2e1b2138UL, 0x4d2c6dfcUL,
    0x53380d13UL, 0x650a7354UL, 0x766a0abbUL, 0x81c2c92eUL, 0x92722c85UL,
    0xa2bfe8a1UL, 0xa81a664bUL, 0xc24b8b70UL, 0xc76c51a3UL, 0xd192e819UL,
    0xd6990624UL, 0xf40e3585UL, 0x106aa070UL, 0x19a4c116UL, 0x1e376c08UL,
    0x2748774cUL, 0x34b0bcb5UL, 0x391c0cb3UL, 0x4ed8aa4aUL, 0x5b9cca4fUL,
    0x682e6ff3UL, 0x748f82eeUL, 0x78a5636fUL, 0x84c87814UL, 0x8cc70208UL,
    0x90befffaUL, 0xa4506cebUL, 0xbef9a3f7UL, 0xc67178f2UL
};

/* Various logical functions */
#define Ch(x,y,z)       (z ^ (x & (y ^ z)))
#define Maj(x,y,z)      (((x | y) & z) | (x & y))
#define S(x, n)         RORc((x),(n))
#define R(x, n)         (((x)&0xFFFFFFFFUL)>>(n))
#define Sigma0(x)       (S(x, 2) ^ S(x, 13) ^ S(x, 22))
#define Sigma1(x)       (S(x, 6) ^ S(x, 11) ^ S(x, 25))
#define Gamma0(x)       (S(x, 7) ^ S(x, 18) ^ R(x, 3))
#define Gamma1(x)       (S(x, 17) ^ S(x, 19) ^ R(x, 10))

/*##########################################################################
#
#   Name       : TSha256Hash::TSha256Hash
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSha256Hash::TSha256Hash()
  : THash(64)
{
    Init();
}

/*##########################################################################
#
#   Name       : TSha256Hash::Init
#
#   Purpose....: Initialize state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha256Hash::Init()
{
    state[0] = 0x6A09E667;
    state[1] = 0xBB67AE85;
    state[2] = 0x3C6EF372;
    state[3] = 0xA54FF53A;
    state[4] = 0x510E527F;
    state[5] = 0x9B05688C;
    state[6] = 0x1F83D9AB;
    state[7] = 0x5BE0CD19;

   THash::Reset();
}

/*##########################################################################
#
#   Name       : TSha256Hash::Reset
#
#   Purpose....: Hash state reset method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha256Hash::Reset()
{
    Init();
}

/*##########################################################################
#
#   Name       : TSha256Hash::Compress
#
#   Purpose....: Add data to hash
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha256Hash::Compress(unsigned char *buf)
{
    unsigned long S[8], W[64], t0, t1;
    unsigned long t;
    int i;

    /* copy state into S */
    for (i = 0; i < 8; i++)
        S[i] = state[i];

    /* copy the state into 512-bits into W[0..15] */
    for (i = 0; i < 16; i++)
        W[i] = RdosLoad32H(buf + (4*i));

    /* fill W[16..63] */
    for (i = 16; i < 64; i++)
        W[i] = Gamma1(W[i - 2]) + W[i - 7] + Gamma0(W[i - 15]) + W[i - 16];

    /* Compress */

#define RND(a,b,c,d,e,f,g,h,i)                         \
     t0 = h + Sigma1(e) + Ch(e, f, g) + K[i] + W[i];   \
     t1 = Sigma0(a) + Maj(a, b, c);                    \
     d += t0;                                          \
     h  = t0 + t1;

     for (i = 0; i < 64; ++i) 
     {
         RND(S[0],S[1],S[2],S[3],S[4],S[5],S[6],S[7],i);
         t = S[7]; S[7] = S[6]; S[6] = S[5]; S[5] = S[4];
         S[4] = S[3]; S[3] = S[2]; S[2] = S[1]; S[1] = S[0]; S[0] = t;
     }
#undef RND

    /* feedback */
    for (i = 0; i < 8; i++)
        state[i] = state[i] + S[i];
}

/*##########################################################################
#
#   Name       : TSha256Hash::GetHashSize
#
#   Purpose....: Get hash size (in bytes)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSha256Hash::GetHashSize()
{
    return 32;
}

/*##########################################################################
#
#   Name       : TSha256Hash::GetHashData
#
#   Purpose....: Get hash data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha256Hash::GetHashData(char *outbuf)
{
    int i;

    /* increase the length of the message */
    length += curlen * 8;

    /* append the '1' bit */
    buf[curlen++] = (unsigned char)0x80;

    /* if the length is currently above 56 bytes we append zeros
     * then compress.  Then we can fall back to padding zeros and length
     * encoding like normal.
     */
    if (curlen > 56) 
    {
        while (curlen < 64) 
            buf[curlen++] = (unsigned char)0;
        Compress(buf);
        curlen = 0;
    }

    /* pad upto 56 bytes of zeroes */
    while (curlen < 56)
        buf[curlen++] = (unsigned char)0;

    /* store length */
    RdosStore64H(buf+56, length);
    Compress(buf);

    /* copy output */
    for (i = 0; i < 8; i++)
        RdosStore32H((unsigned char *)outbuf+4*i, state[i]);
}

/*##########################################################################
#
#   Name       : TSha256Hash::Test
#
#   Purpose....: Test class
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSha256Hash::Test()
{
    static const struct 
    {
        char *msg;
        char hash[32];
    } tests[] = {
        { "abc",
          { 0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
            0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
            0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
            0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad }
        },
        { "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
          { 0x24, 0x8d, 0x6a, 0x61, 0xd2, 0x06, 0x38, 0xb8,
            0xe5, 0xc0, 0x26, 0x93, 0x0c, 0x3e, 0x60, 0x39,
            0xa3, 0x3c, 0xe4, 0x59, 0x64, 0xff, 0x21, 0x67,
            0xf6, 0xec, 0xed, 0xd4, 0x19, 0xdb, 0x06, 0xc1 }
        },
    };

    int i;
    char tmp[32];
    TSha256Hash Hash;

    for (i = 0; i < (int)(sizeof(tests) / sizeof(tests[0])); i++) 
    {
        Hash.Reset();
        Hash.Add(tests[i].msg, strlen(tests[i].msg));
        Hash.GetHashData(tmp);
        if (memcmp(tmp, tests[i].hash, 32) != 0)
        {
            return 0;
        }
    }
    return 1;
}
