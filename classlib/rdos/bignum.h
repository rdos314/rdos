/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
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
# The author of this program may be contacted at leif@rdos.net
#
# bignum.h
# Big number class
#
########################################################################*/

#ifndef _BIGNUM_H
#define _BIGNUM_H

#include "str.h"

class TBigNum
{
public:
    TBigNum();
    TBigNum(int Value);
    TBigNum(long long Value);
    TBigNum(unsigned int Value);
    TBigNum(unsigned long long Value);
    TBigNum(const char *str);
    TBigNum(TString &str);
    ~TBigNum();

    void LoadSigned(const char *buf, int size);
    void LoadUnsigned(const char *buf, int size);
    void SaveSigned(char *buf, int size);
    void SaveUnsigned(char *buf, int size);

    void LoadDec(const char *str);
    void LoadHex(const char *str);
    void LoadDec(TString &str);
    void LoadHex(TString &str);

    TString GetHex(int digits);
    TString GetDec();

protected:

private:
    int FHandle;
};

#endif

