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
# sha1.cpp
# SHA1 hash class
#
########################################################################*/

#include <string.h>

#include "helper.h"
#include "sha1.h"

#define F0(x,y,z)  (z ^ (x & (y ^ z)))
#define F1(x,y,z)  (x ^ y ^ z)
#define F2(x,y,z)  ((x & y) | (z & (x | y)))
#define F3(x,y,z)  (x ^ y ^ z)

#define FF0(a,b,c,d,e,i) e = (ROLc(a, 5) + F0(b,c,d) + e + W[i] + 0x5a827999UL); b = ROLc(b, 30);
#define FF1(a,b,c,d,e,i) e = (ROLc(a, 5) + F1(b,c,d) + e + W[i] + 0x6ed9eba1UL); b = ROLc(b, 30);
#define FF2(a,b,c,d,e,i) e = (ROLc(a, 5) + F2(b,c,d) + e + W[i] + 0x8f1bbcdcUL); b = ROLc(b, 30);
#define FF3(a,b,c,d,e,i) e = (ROLc(a, 5) + F3(b,c,d) + e + W[i] + 0xca62c1d6UL); b = ROLc(b, 30);


/*##########################################################################
#
#   Name       : TSha1Hash::TSha1Hash
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSha1Hash::TSha1Hash()
  : THash(64)
{
    Init();
}

/*##########################################################################
#
#   Name       : TSha1Hash::Init
#
#   Purpose....: Initialize state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha1Hash::Init()
{
   state[0] = 0x67452301UL;
   state[1] = 0xefcdab89UL;
   state[2] = 0x98badcfeUL;
   state[3] = 0x10325476UL;
   state[4] = 0xc3d2e1f0UL;

   THash::Reset();
}

/*##########################################################################
#
#   Name       : TSha1Hash::Reset
#
#   Purpose....: Hash state reset method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha1Hash::Reset()
{
    Init();
}

/*##########################################################################
#
#   Name       : TSha1Hash::Compress
#
#   Purpose....: Add data to hash
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha1Hash::Compress(unsigned char *buf)
{
    unsigned int a,b,c,d,e,W[80],i;

    /* copy the state into 512-bits into W[0..15] */
    for (i = 0; i < 16; i++)
        W[i] = RdosLoad32H(buf + 4*i);

    /* copy state */
    a = state[0];
    b = state[1];
    c = state[2];
    d = state[3];
    e = state[4];

    /* expand it */
    for (i = 16; i < 80; i++) {
        W[i] = ROL(W[i-3] ^ W[i-8] ^ W[i-14] ^ W[i-16], 1); 
    }

    for (i = 0; i < 20; ) {
       FF0(a,b,c,d,e,i++);
       FF0(e,a,b,c,d,i++);
       FF0(d,e,a,b,c,i++);
       FF0(c,d,e,a,b,i++);
       FF0(b,c,d,e,a,i++);
    }

    /* round two */
    for (; i < 40; )  { 
       FF1(a,b,c,d,e,i++);
       FF1(e,a,b,c,d,i++);
       FF1(d,e,a,b,c,i++);
       FF1(c,d,e,a,b,i++);
       FF1(b,c,d,e,a,i++);
    }

    /* round three */
    for (; i < 60; )  { 
       FF2(a,b,c,d,e,i++);
       FF2(e,a,b,c,d,i++);
       FF2(d,e,a,b,c,i++);
       FF2(c,d,e,a,b,i++);
       FF2(b,c,d,e,a,i++);
    }

    /* round four */
    for (; i < 80; )  { 
       FF3(a,b,c,d,e,i++);
       FF3(e,a,b,c,d,i++);
       FF3(d,e,a,b,c,i++);
       FF3(c,d,e,a,b,i++);
       FF3(b,c,d,e,a,i++);
    }

    /* store */
    state[0] = state[0] + a;
    state[1] = state[1] + b;
    state[2] = state[2] + c;
    state[3] = state[3] + d;
    state[4] = state[4] + e;
}

/*##########################################################################
#
#   Name       : TSha1Hash::GetHashSize
#
#   Purpose....: Get hash size (in bytes)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSha1Hash::GetHashSize()
{
    return 20;
}

/*##########################################################################
#
#   Name       : TSha1Hash::GetHashData
#
#   Purpose....: Get hash data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSha1Hash::GetHashData(char *outbuf)
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
    for (i = 0; i < 5; i++)
        RdosStore32H((unsigned char *)outbuf+4*i, state[i]);
}

/*##########################################################################
#
#   Name       : TSha1Hash::Test
#
#   Purpose....: Test class
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSha1Hash::Test()
{
    static const struct {
        char *msg;
        char hash[20];
    } tests[] = 
    {
        { "abc",
          { 0xa9, 0x99, 0x3e, 0x36, 0x47, 0x06, 0x81, 0x6a,
            0xba, 0x3e, 0x25, 0x71, 0x78, 0x50, 0xc2, 0x6c,
            0x9c, 0xd0, 0xd8, 0x9d }
        },
        { "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
          { 0x84, 0x98, 0x3E, 0x44, 0x1C, 0x3B, 0xD2, 0x6E,
            0xBA, 0xAE, 0x4A, 0xA1, 0xF9, 0x51, 0x29, 0xE5,
            0xE5, 0x46, 0x70, 0xF1 }
        }
    };

    int i;
    char tmp[20];
    TSha1Hash Hash;

    for (i = 0; i < (int)(sizeof(tests) / sizeof(tests[0]));  i++)
    {
        Hash.Reset();
        Hash.Add(tests[i].msg, strlen(tests[i].msg));
        Hash.GetHashData(tmp);
        if (memcmp(tmp, tests[i].hash, 20) != 0)
        {
            return 0;
        }
    }
    return 1;
}
