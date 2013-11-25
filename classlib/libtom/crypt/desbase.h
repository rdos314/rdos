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
# desbase.h
# Des base class
#
########################################################################*/

#ifndef _DESBASE_H
#define _DESBASE_H

#include "crypt.h"

class TDesBase : public TCrypt
{
public:
    TDesBase();
    virtual ~TDesBase();

protected:
    void CooKey(const unsigned long *Raw, unsigned long *KeyOut);
    void CreateKey(const unsigned char *KeyIn, short int edf, unsigned long *KeyOut);
    void DoDes(unsigned long *Block, const unsigned long *Keys);
        
};

#endif
