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
# string.h
# String class
#
########################################################################*/

#ifndef _STRING_H
#define _STRING_H

#include <stdarg.h>
#include "shareobj.h"

class TString : public TShareObject
{
friend class TStringListNode;
public:
    TString();
    TString(const TString &source);
    TString(const char *str);
    TString(const char *str, int size);
    virtual ~TString();

    const TString &operator=(const TString &src);
    const TString &operator=(const char *str);
    const TString &operator+=(const char *str);
    const TString &operator+=(char ch);
    const TString &operator+=(const TString& str);
    int operator==(const TString &dest) const;
    int operator!=(const TString &dest) const;
    int operator>(const TString &dest) const;
    int operator>=(const TString &dest) const;
    int operator<(const TString &dest) const;
    int operator<=(const TString &dest) const;
    char operator[](int n) const;

    int printf(const char *fmt, ...);
    int prtf(const char *frm, va_list args);

    void Reset();
    const char *GetData() const;
    int GetSize() const;

    const char *Find(char ch) const;
    const char *Find(const char *str) const;
    void Upper();
    void Lower();
    void RemoveCrLf();
    void Append(char ch);
    void Append(const char *str);
    void Append(const char *str, int size);
    void Replace(const char *src, const char *dest);

    void ConcatCopy(const char *str1, int len1, const char *str2, int len2);

    virtual int Compare(const TShareObject &str) const;

protected:
    virtual char Upper(char ch);
    virtual char Lower(char ch);

    void Pad(int count, const char *str);

#ifndef __RDOS__
        int Number(long num, int base, int size, int precision, int type);
#endif

    void ReplaceOne(char *ptr, const char *src, const char *dest);
    void AllocCopy(TString& dest, int CopyLen, int CopyIndex, int ExtraLen) const;
    void ConcatInPlace(const char *str, int size);
};

TString operator+(const TString& str1, const TString& str2);
TString operator+(const TString& str, const char *cstr);
TString operator+(const char *cstr, const TString& str);

#endif
