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
# bignum.cpp
# Big number class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "bignum.h"
#include "rdos.h"

/*##########################################################################
#
#   Name       : TBigNum::TBigNum
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBigNum::TBigNum()
{
    FHandle = RdosCreateBigNum();
}

/*##########################################################################
#
#   Name       : TBigNum::TBigNum
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBigNum::TBigNum(int val)
{
    FHandle = RdosCreateBigNum();
    RdosLoadSignedBigNum(FHandle, (const char *)&val, 4);
}

/*##########################################################################
#
#   Name       : TBigNum::TBigNum
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBigNum::TBigNum(long long val)
{
    FHandle = RdosCreateBigNum();
    RdosLoadSignedBigNum(FHandle, (const char *)&val, 8);
}

/*##########################################################################
#
#   Name       : TBigNum::TBigNum
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBigNum::TBigNum(unsigned int val)
{
    FHandle = RdosCreateBigNum();
    RdosLoadUnsignedBigNum(FHandle, (const char *)&val, 4);
}

/*##########################################################################
#
#   Name       : TBigNum::TBigNum
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBigNum::TBigNum(unsigned long long val)
{
    FHandle = RdosCreateBigNum();
    RdosLoadUnsignedBigNum(FHandle, (const char *)&val, 8);
}

/*##########################################################################
#
#   Name       : TBigNum::~TBigNum
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBigNum::~TBigNum()
{
    RdosDeleteBigNum(FHandle);
}

/*##########################################################################
#
#   Name       : TBigNum::GetHex
#
#   Purpose....: Get number as hex string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TBigNum::GetHex(int digits)
{
    int size;
    char *buf;
    char *ptr;

    size = digits + 1;
    buf = new char[size]; 
    RdosSaveHexStrBigNum(FHandle, buf, size);

    TString str(buf);
    delete buf;

    return str;
}

/*##########################################################################
#
#   Name       : TBigNum::GetDec
#
#   Purpose....: Get number as decimal string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TBigNum::GetDec()
{
    int size;
    char *buf;
    char *ptr;

    size = RdosGetDecStrSizeBigNum(FHandle) + 1;
    buf = new char[size]; 
    RdosSaveDecStrBigNum(FHandle, buf, size);

    ptr = buf;
    while (*ptr == ' ')
        ptr++;   

    TString str(ptr);
    delete buf;

    return str;
}

/*##########################################################################
#
#   Name       : TBigNum::LoadSigned
#
#   Purpose....: Load as signed data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::LoadSigned(const char *buf, int size)
{
    RdosLoadSignedBigNum(FHandle, buf, size);
}

/*##########################################################################
#
#   Name       : TBigNum::LoadUnsigned
#
#   Purpose....: Load as unsigned data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::LoadUnsigned(const char *buf, int size)
{
    RdosLoadUnsignedBigNum(FHandle, buf, size);
}


/*##########################################################################
#
#   Name       : TBigNum::SaveSigned
#
#   Purpose....: Save as signed data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::SaveSigned(char *buf, int size)
{
    RdosSaveSignedBigNum(FHandle, buf, size);
}

/*##########################################################################
#
#   Name       : TBigNum::SaveUnsigned
#
#   Purpose....: Save as unsigned data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::SaveUnsigned(char *buf, int size)
{
    RdosSaveUnsignedBigNum(FHandle, buf, size);
}
