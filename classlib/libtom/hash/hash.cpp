/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2012, Leif Ekblad
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
