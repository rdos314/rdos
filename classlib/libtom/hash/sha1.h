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
# sha1.h
# SHA1 hash class
#
########################################################################*/

#ifndef _SHA1_H
#define _SHA1_H

#include "hash.h"

class TSha1Hash : public THash
{
public:
    TSha1Hash();

    virtual void Reset();
    virtual int GetHashSize();
    virtual void GetHashData(char *buf);

    static int Test();

protected:
    void Init();
    virtual void Compress(unsigned char *buf);

    unsigned int state[5];
};

#endif

