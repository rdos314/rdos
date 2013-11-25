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
# des1.h
# Single pass DES class
#
########################################################################*/

#ifndef _DES1_H
#define _DES1_H

#include "desbase.h"

class TDes1 : public TDesBase
{
public:
    TDes1(const char *Key);
    virtual ~TDes1();

    virtual int GetKeySize();
    virtual void SetupKey(const char *Key);
    virtual void Encrypt(char *buf, int size);
    virtual void Decrypt(char *buf, int size);

    int Test();

protected:
    void Setup(const unsigned char *Key);
    void EncryptBlock(const unsigned char *Pt, unsigned char *Ct);
    void DecryptBlock(const unsigned char *Ct, unsigned char *Pt);
    
    unsigned long ek;
    unsigned long dk;
};

#endif
