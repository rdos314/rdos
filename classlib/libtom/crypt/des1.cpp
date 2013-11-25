/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2013, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# LibTomCrypt, modular cryptographic library -- Tom St Denis was ported to
# a C++ class-interface
# Tom St Denis, tomstdenis@gmail.com, http://libtom.org
#
# The C++ porter of this program may be contacted at leif@rdos.net
#
# des1.cpp
# single des class
#
########################################################################*/

#include <string.h>

#include "des1.h"
#include "helper.h"

#define EN0 0 
#define DE1 1

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TDes1::TDes1
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDes1::TDes1(const char *Key)
{
    SetupKey(Key);
}

/*##########################################################################
#
#   Name       : TDes1::~TDes1
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDes1::~TDes1()
{
}

/*##########################################################################
#
#   Name       : TDes1::GetKeySize
#
#   Purpose....: Get key size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDes1::GetKeySize()
{
    return 8;
}

/*##########################################################################
#
#   Name       : TDes1::Setup
#
#   Purpose....: Setup keys
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes1::Setup(const unsigned char *key)
{
    CreateKey(key, EN0, &ek);
    CreateKey(key, DE1, &dk);
}

/*##########################################################################
#
#   Name       : TDes1::EncryptBlock
#
#   Purpose....: Encrypt block of 8 bytes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes1::EncryptBlock(const unsigned char *pt, unsigned char *ct)
{
    unsigned long work[2];

    LOAD32H(work[0], pt+0);
    LOAD32H(work[1], pt+4);

    DoDes(work, &ek);

    STORE32H((unsigned char *)work[0],(unsigned)(ct+0));
    STORE32H((unsigned char *)work[1],(unsigned)(ct+4));
}

/*##########################################################################
#
#   Name       : TDes1::DecryptBlock
#
#   Purpose....: Decrypt block of 8 bytes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes1::DecryptBlock(const unsigned char *ct, unsigned char *pt)
{
    unsigned long work[2];

    LOAD32H(work[0], ct+0);
    LOAD32H(work[1], ct+4);

    DoDes(work, &dk);

    STORE32H((unsigned char *)work[0],(unsigned)(pt+0));
    STORE32H((unsigned char *)work[1],(unsigned)(pt+4));
}

/*##########################################################################
#
#   Name       : TDes1::Test
#
#   Purpose....: Test
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDes1::Test()
{
    static const struct des_test_case {
        int num, mode; /* mode 1 = encrypt */
        unsigned char key[8], txt[8], out[8];
    } cases[] = {
        { 1, 1,     { 0x10, 0x31, 0x6E, 0x02, 0x8C, 0x8F, 0x3B, 0x4A },
                    { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x82, 0xDC, 0xBA, 0xFB, 0xDE, 0xAB, 0x66, 0x02 } },
        { 2, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x95, 0xF8, 0xA5, 0xE5, 0xDD, 0x31, 0xD9, 0x00 },
                    { 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 3, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0xDD, 0x7F, 0x12, 0x1C, 0xA5, 0x01, 0x56, 0x19 },
                    { 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 4, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x2E, 0x86, 0x53, 0x10, 0x4F, 0x38, 0x34, 0xEA },
                    { 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 5, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x4B, 0xD3, 0x88, 0xFF, 0x6C, 0xD8, 0x1D, 0x4F },
                    { 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 6, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x20, 0xB9, 0xE7, 0x67, 0xB2, 0xFB, 0x14, 0x56 },
                    { 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 7, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x55, 0x57, 0x93, 0x80, 0xD7, 0x71, 0x38, 0xEF },
                    { 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 8, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x6C, 0xC5, 0xDE, 0xFA, 0xAF, 0x04, 0x51, 0x2F },
                    { 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 9, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x0D, 0x9F, 0x27, 0x9B, 0xA5, 0xD8, 0x72, 0x60 }, 
                    { 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        {10, 1,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0xD9, 0x03, 0x1B, 0x02, 0x71, 0xBD, 0x5A, 0x0A },
                    { 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },

        { 1, 0,     { 0x10, 0x31, 0x6E, 0x02, 0x8C, 0x8F, 0x3B, 0x4A },
                    { 0x82, 0xDC, 0xBA, 0xFB, 0xDE, 0xAB, 0x66, 0x02 },
                    { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 } },
        { 2, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x95, 0xF8, 0xA5, 0xE5, 0xDD, 0x31, 0xD9, 0x00 } },
        { 3, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0xDD, 0x7F, 0x12, 0x1C, 0xA5, 0x01, 0x56, 0x19 } },
        { 4, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x2E, 0x86, 0x53, 0x10, 0x4F, 0x38, 0x34, 0xEA } },
        { 5, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x4B, 0xD3, 0x88, 0xFF, 0x6C, 0xD8, 0x1D, 0x4F } },
        { 6, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x20, 0xB9, 0xE7, 0x67, 0xB2, 0xFB, 0x14, 0x56 } },
        { 7, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x55, 0x57, 0x93, 0x80, 0xD7, 0x71, 0x38, 0xEF } },
        { 8, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x6C, 0xC5, 0xDE, 0xFA, 0xAF, 0x04, 0x51, 0x2F } },
        { 9, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0x0D, 0x9F, 0x27, 0x9B, 0xA5, 0xD8, 0x72, 0x60 } }, 
        {10, 0,     { 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 },
                    { 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
                    { 0xD9, 0x03, 0x1B, 0x02, 0x71, 0xBD, 0x5A, 0x0A } }
    };
    int i, y;
    unsigned char tmp[8];

    for(i=0; i < (int)(sizeof(cases)/sizeof(cases[0])); i++)
    {
        Setup(cases[i].key);

        if (cases[i].mode != 0) { 
           EncryptBlock(cases[i].txt, tmp);
        } else {
           DecryptBlock(cases[i].txt, tmp);
        }

        if (memcmp(cases[i].out, tmp, sizeof(tmp)) != 0) {
           return FALSE;
        }

      /* now see if we can encrypt all zero bytes 1000 times, decrypt and come back where we started */
      for (y = 0; y < 8; y++) tmp[y] = 0;
      for (y = 0; y < 1000; y++) EncryptBlock(tmp, tmp);
      for (y = 0; y < 1000; y++) DecryptBlock(tmp, tmp);
      for (y = 0; y < 8; y++) if (tmp[y] != 0) return FALSE;
    }

    return TRUE;
}
