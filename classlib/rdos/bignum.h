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

    const TBigNum &operator=(int value);
    const TBigNum &operator=(long long value);
    const TBigNum &operator=(unsigned int value);
    const TBigNum &operator=(unsigned long long value);

    const TBigNum &operator+=(int value);
    const TBigNum &operator+=(long long value);
    const TBigNum &operator+=(unsigned int value);
    const TBigNum &operator+=(unsigned long long value);

    const TBigNum &operator-=(int value);
    const TBigNum &operator-=(long long value);
    const TBigNum &operator-=(unsigned int value);
    const TBigNum &operator-=(unsigned long long value);

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

