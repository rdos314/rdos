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
# des3.cpp
# Tripple DES class
#
########################################################################*/

#include <string.h>

#include "des3.h"
#include "helper.h"

#define EN0 0 
#define DE1 1

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TDes3::TDes3
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDes3::TDes3()
{
}

/*##########################################################################
#
#   Name       : TDes3::~TDes3
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDes3::~TDes3()
{
}

/*##########################################################################
#
#   Name       : TDes3::GetKeySize
#
#   Purpose....: Get key size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDes3::GetKeySize()
{
    return 24;
}

/*##########################################################################
#
#   Name       : TDes3::SetupKey
#
#   Purpose....: Setup keys
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes3::SetupKey(const char *Key)
{
    const unsigned char *ukey = (const unsigned char *)Key;
    
    CreateKey(ukey, EN0, ek[0]);
    CreateKey(ukey + 8, DE1, ek[1]);
    CreateKey(ukey + 16, EN0, ek[2]);
    
    CreateKey(ukey, DE1, dk[2]);
    CreateKey(ukey + 8, EN0, dk[1]);
    CreateKey(ukey + 16, DE1, dk[0]);
}

/*##########################################################################
#
#   Name       : TDes3::Encrypt
#
#   Purpose....: Encrypt data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes3::Encrypt(char *buf, int size)
{
    char *ptr = buf;
    int len = size;
    int i;
    unsigned char pt[8];
    unsigned char ct[8];

    while (len)
    {
        if (len < 8)
        {
            memcpy(pt, ptr, len);
            for (i = len; i < 8; i++)
                pt[i] = 0;
        }
        else
            memcpy(pt, ptr, 8);

        EncryptBlock(pt, ct);

        if (len < 8)
        {
            memcpy(ptr, ct, len);
            len = 0;
        }
        else
        {
            memcpy(ptr, ct, 8);
            ptr += 8;
            len -= 8;
        }
    }
}

/*##########################################################################
#
#   Name       : TDes3::Decrypt
#
#   Purpose....: Decrypt data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes3::Decrypt(char *buf, int size)
{
    char *ptr = buf;
    int len = size;
    int i;
    unsigned char pt[8];
    unsigned char ct[8];

    while (len)
    {
        if (len < 8)
        {
            memcpy(ct, ptr, len);
            for (i = len; i < 8; i++)
                ct[i] = 0;
        }
        else
            memcpy(ct, ptr, 8);

        DecryptBlock(ct, pt);

        if (len < 8)
        {
            memcpy(ptr, pt, len);
            len = 0;
        }
        else
        {
            memcpy(ptr, pt, 8);
            ptr += 8;
            len -= 8;
        }
    }
}

/*##########################################################################
#
#   Name       : TDes3::Setup
#
#   Purpose....: Setup keys
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes3::Setup(const unsigned char *key)
{
    CreateKey(key, EN0, ek[0]);
    CreateKey(key + 8, DE1, ek[1]);
    CreateKey(key + 16, EN0, ek[2]);
    
    CreateKey(key, DE1, dk[2]);
    CreateKey(key + 8, EN0, dk[1]);
    CreateKey(key + 16, DE1, dk[0]);
}

/*##########################################################################
#
#   Name       : TDes3::EncryptBlock
#
#   Purpose....: Encrypt block of 8 bytes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes3::EncryptBlock(const unsigned char *pt, unsigned char *ct)
{
    unsigned long work[2];

    work[0] = (unsigned long)RdosLoad32H(pt+0);
    work[1] = (unsigned long)RdosLoad32H(pt+4);

    DoDes(work, ek[0]);
    DoDes(work, ek[1]);
    DoDes(work, ek[2]);

    RdosStore32H((unsigned char *)(ct+0), (unsigned int)work[0]);
    RdosStore32H((unsigned char *)(ct+4), (unsigned int)work[1]);
}

/*##########################################################################
#
#   Name       : TDes3::DecryptBlock
#
#   Purpose....: Decrypt block of 8 bytes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDes3::DecryptBlock(const unsigned char *ct, unsigned char *pt)
{
    unsigned long work[2];

    work[0] = (unsigned long)RdosLoad32H(ct+0);
    work[1] = (unsigned long)RdosLoad32H(ct+4);

    DoDes(work, dk[0]);
    DoDes(work, dk[1]);
    DoDes(work, dk[2]);

    RdosStore32H((unsigned char *)(pt+0), (unsigned int)work[0]);
    RdosStore32H((unsigned char *)(pt+4), (unsigned int)work[1]);
}

/*##########################################################################
#
#   Name       : TDes3::Test
#
#   Purpose....: Test
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDes3::Test()
{
   unsigned char key[24], pt[8], ct[8], tmp[8];
   int x;

   for (x = 0; x < 8; x++)
       pt[x] = x;
   
   for (x = 0; x < 24; x++)
       key[x] = x;

   Setup(key);
   
   EncryptBlock(pt, ct);
   DecryptBlock(ct, tmp);
   
   if (memcmp(pt, tmp, 8) != 0) 
      return FALSE;

    return TRUE;
}
