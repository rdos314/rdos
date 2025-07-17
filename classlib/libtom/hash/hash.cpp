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
# hash.cpp
# Hashing base class
#
########################################################################*/

#include <memory.h>

#include "helper.h"
#include "hash.h"

/*##########################################################################
#
#   Name       : THash::THash
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THash::THash(int buf_size)
{
    block_size = buf_size;
    buf = new unsigned char[buf_size];
}

/*##########################################################################
#
#   Name       : THash::~THash
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THash::~THash()
{
    delete buf;
}
    
/*##########################################################################
#
#   Name       : THash::Reset
#
#   Purpose....: Reset hash variables
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THash::Reset()
{
   curlen = 0;
   length = 0;
}

/*##########################################################################
#
#   Name       : THash::Add
#
#   Purpose....: Add data to hash
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THash::Add(char *addbuf, int size)
{
    unsigned long n;
    unsigned char *inbuf = (unsigned char *)addbuf;

    while (size > 0)
    {
        if (curlen == 0 && size >= block_size) 
        {
           Compress(inbuf);
           length += block_size * 8;
           inbuf += block_size;
           size -= block_size;
        } 
        else
        {
           n = MIN(size, (block_size - curlen));
           memcpy(buf + curlen, inbuf, n);
           curlen += n;
           inbuf += n;
           size -= n;
           if (curlen == block_size) 
           {
              Compress(buf);
              length += 8 * block_size;
              curlen = 0;
           }
        }
    }
}
