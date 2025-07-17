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
#   Name       : TBigNum::TBigNum
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBigNum::TBigNum(const char *str)
{
    FHandle = RdosCreateBigNum();
    RdosLoadDecStrBigNum(FHandle, str);
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
TBigNum::TBigNum(TString &str)
{
    FHandle = RdosCreateBigNum();
    RdosLoadDecStrBigNum(FHandle, str.GetData());
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
#   Name       : TBigNum::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator=(int val)
{
    RdosLoadSignedBigNum(FHandle, (const char *)&val, 4);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator=(long long val )
{
    RdosLoadSignedBigNum(FHandle, (const char *)&val, 8);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator=(unsigned int val)
{
    RdosLoadUnsignedBigNum(FHandle, (const char *)&val, 4);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator=(unsigned long long val)
{
    RdosLoadUnsignedBigNum(FHandle, (const char *)&val, 8);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator+=
#
#   Purpose....: += operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator+=(int val)
{
    RdosAddSignedBigNum(FHandle, (const char *)&val, 4);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator+=
#
#   Purpose....: += operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator+=(long long val)
{
    RdosAddSignedBigNum(FHandle, (const char *)&val, 8);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator+=
#
#   Purpose....: += operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator+=(unsigned int val)
{
    RdosAddUnsignedBigNum(FHandle, (const char *)&val, 4);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator+=
#
#   Purpose....: += operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator+=(unsigned long long val)
{
    RdosAddUnsignedBigNum(FHandle, (const char *)&val, 8);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator-=
#
#   Purpose....: -= operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator-=(int val)
{
    RdosSubSignedBigNum(FHandle, (const char *)&val, 4);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator-=
#
#   Purpose....: -= operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator-=(long long val)
{
    RdosSubSignedBigNum(FHandle, (const char *)&val, 8);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator-=
#
#   Purpose....: -= operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator-=(unsigned int val)
{
    RdosSubUnsignedBigNum(FHandle, (const char *)&val, 4);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::operator-=
#
#   Purpose....: -= operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TBigNum &TBigNum::operator-=(unsigned long long val)
{
    RdosSubUnsignedBigNum(FHandle, (const char *)&val, 8);
    return *this;
}

/*##########################################################################
#
#   Name       : TBigNum::LoadDec
#
#   Purpose....: Load from decimal string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::LoadDec(const char *str)
{
    RdosLoadDecStrBigNum(FHandle, str);
}

/*##########################################################################
#
#   Name       : TBigNum::LoadHex
#
#   Purpose....: Load from hex string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::LoadHex(const char *str)
{
    RdosLoadHexStrBigNum(FHandle, str);
}

/*##########################################################################
#
#   Name       : TBigNum::LoadDec
#
#   Purpose....: Load from decimal string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::LoadDec(TString &str)
{
    RdosLoadDecStrBigNum(FHandle, str.GetData());
}

/*##########################################################################
#
#   Name       : TBigNum::LoadHex
#
#   Purpose....: Load from hex string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBigNum::LoadHex(TString &str)
{
    RdosLoadHexStrBigNum(FHandle, str.GetData());
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
