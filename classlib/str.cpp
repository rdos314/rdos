/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# str.cpp
# String class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdarg.h>

#include "str.h"
#include "section.h"

#ifdef __RDOS__
#include "rdos.h"
#endif

TSection Section("String");

#define ZEROPAD 1               /* pad with zero */
#define SIGN    2               /* unsigned/signed long */
#define PLUS    4               /* show plus */
#define SPACE   8               /* space if plus */
#define LEFT    16              /* left justified */
#define SPECIAL 32              /* 0x */
#define LARGE   64              /* use 'ABCDEF' instead of 'abcdef' */

#define FALSE 0
#define TRUE !FALSE

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : PrintfCallback
#
#   Purpose....: Printf callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintfCallback(void *param, char ch)
{
    TString *str = (TString *)param;
    str->Append(ch);
}

#endif

/*##########################################################################
#
#   Name       : TString::TString
#
#   Purpose....: Constructor for string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString::TString()
{
}

/*##########################################################################
#
#   Name       : TString::TString
#
#   Purpose....: Copy constructor for string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString::TString(const TString &src)
 : TShareObject(src)
{
}

/*##########################################################################
#
#   Name       : TString::TString
#
#   Purpose....: Construct from C-string
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString::TString(const char *str)
 : TShareObject(str, strlen(str) + 1)
{
}

/*##########################################################################
#
#   Name       : TString::TString
#
#   Purpose....: Construct from C-string and length
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString::TString(const char *str, int size)
 : TShareObject(str, size + 1)
{
    FBuf[size] = 0;
}

/*##########################################################################
#
#   Name       : TString::~TString
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString::~TString()
{
}

/*##########################################################################
#
#   Name       : TString::AllocCopy
#
#   Purpose....: Allocate a copy
#
#   In params..: dest
#                                CopyLen
#                                CopyIndex
#                                ExtraLen
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::AllocCopy(TString& dest, int CopyLen, int CopyIndex, int ExtraLen) const
{
    int NewLen = CopyLen + ExtraLen;

    dest.FSection.Enter();

    dest.AllocBuffer(NewLen + 1);
    memcpy(dest.FBuf, FBuf+CopyIndex, CopyLen);
    *(dest.FBuf+CopyLen) = 0;

    dest.FSection.Leave();
}

/*##########################################################################
#
#   Name       : TString::ConcatCopy
#
#   Purpose....: Concat strings
#
#   In params..: len1
#                                str1
#                                len2
#                                str2
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::ConcatCopy(const char *str1, int len1, const char *str2, int len2)
{
    int NewLen = len1 + len2;

    FSection.Enter();

    AllocBuffer(NewLen + 1);
    memcpy(FBuf, str1, len1);
    memcpy(FBuf+len1, str2, len2);
    *(FBuf+len1+len2) = 0;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TString::ConcatInPlace
#
#   Purpose....: Concatenation in place
#
#   In params..: x
#                                size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::ConcatInPlace(const char *str, int size)
{
    FSection.Enter();

    if (FData == 0)
        AssignCopy(str, size + 1);
    else
    {
        if (size)
        {
                if (FData->FRefs > 1 || FData->FDataSize + size > FData->FAllocSize)
                {
                        TShareObjectData* OldData = FData;
                        ConcatCopy(GetData(), GetSize(), str, size);
                        Release(OldData);
                }
                else
                {
                        memcpy(FBuf + FData->FDataSize - 1, str, size);
                        FData->FDataSize += size;
                        *(FBuf+FData->FDataSize - 1) = 0;
                }
        }
    }
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TString::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TString &TString::operator=(const TString &src)
{
    Load(src);
    return *this;
}

/*##########################################################################
#
#   Name       : TString::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::Compare(const TShareObject &str) const
{
    int res;

    FSection.Enter();

    if (FBuf == 0 || str.FBuf == 0)
    {
        if (FBuf == 0)
        {
            if (str.FBuf == 0)
                res = 0;
            else
                res = 1;
        }
        else
            res = -1;
    }
    else
        res = strcmp(FBuf, str.FBuf);

    FSection.Leave();

    return res;
}

/*##########################################################################
#
#   Name       : TString::operator=
#
#   Purpose....: Assignment operator for C-string
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TString &TString::operator=(const char *str)
{
    AssignCopy(str, strlen(str) + 1);
    return *this;
}

/*##########################################################################
#
#   Name       : TString::operator==
#
#   Purpose....: Compare strings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::operator==(const TString &str) const
{
    if (Compare(str) == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TString::operator!=
#
#   Purpose....: Compare strings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::operator!=(const TString &str) const
{
    if (Compare(str) == 0)
        return FALSE;
    else
        return TRUE;
}

/*##########################################################################
#
#   Name       : TString::operator>
#
#   Purpose....: Compare strings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::operator>(const TString &dest) const
{
    if (Compare(dest) > 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TString::operator<
#
#   Purpose....: Compare strings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::operator<(const TString &dest) const
{
    if (Compare(dest) < 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TString::operator>=
#
#   Purpose....: Compare strings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::operator>=(const TString &dest) const
{
    if (Compare(dest) >= 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TString::operator<=
#
#   Purpose....: Compare strings
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::operator<=(const TString &dest) const
{
    if (Compare(dest) <= 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TString::operator[]
#
#   Purpose....: [] operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TString::operator[](int n) const
{
    char ch = 0;

    FSection.Enter();

    if (FData && FData->FDataSize > n)
        ch = FBuf[n];

    FSection.Leave();

    return ch;
}

/*##########################################################################
#
#   Name       : operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: str1
#                                str2
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString operator+(const TString& str1, const TString& str2)
{
    TString s;
    s.ConcatCopy(str1.GetData(), str1.GetSize(), str2.GetData(), str2.GetSize());
    return s;
}

/*##########################################################################
#
#   Name       : TString::operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: str
#                                cstr
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString operator+(const TString& str, const char *cstr)
{
    TString s;
    s.ConcatCopy(str.GetData(), str.GetSize(), cstr, strlen(cstr));
    return s;
}

/*##########################################################################
#
#   Name       : TString::operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: cstr
#                                str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString operator+(const char *cstr, const TString& str)
{
    TString s;
    s.ConcatCopy(cstr, strlen(cstr), str.GetData(), str.GetSize());
    return s;
}

/*##########################################################################
#
#   Name       : TString::operator+=
#
#   Purpose....: Concat in place operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TString &TString::operator+=(const char *str)
{
    ConcatInPlace(str, strlen(str));
    return *this;
}

/*##########################################################################
#
#   Name       : TString::operator+=
#
#   Purpose....: Concat in place operator
#
#   In params..: ch
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TString &TString::operator+=(char ch)
{
    char str[2];

    str[0] = ch;
    str[1] = 0;

    ConcatInPlace(str, 1);
    return *this;
}

/*##########################################################################
#
#   Name       : TString::operator+=
#
#   Purpose....: Concat in place operator
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TString &TString::operator+=(const TString& str)
{
    ConcatInPlace(str.GetData(), str.GetSize());
    return *this;
}

/*##########################################################################
#
#   Name       : TString::Reset
#
#   Purpose....: Reset
#
#   In params..: str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Reset()
{
    AssignCopy(0, 0);
}

/*##########################################################################
#
#   Name       : TString::GetData
#
#   Purpose....: Get string buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: str
#
##########################################################################*/
const char *TString::GetData() const
{
    if (FBuf)
        return FBuf;
    else
        return "";
}

/*##########################################################################
#
#   Name       : TString::GetSize
#
#   Purpose....: Get size of string
#
#   In params..: *
#   Out params.: *
#   Returns....: size
#
##########################################################################*/
int TString::GetSize() const
{
    int size = 0;

    FSection.Enter();

    if (FData)
        size = FData->FDataSize - 1;

    FSection.Leave();

    return size;
}

/*##########################################################################
#
#   Name       : TString::Find
#
#   Purpose....: Find first occurence of character, and return string
#
#   In params..: ch
#   Out params.: *
#   Returns....: str
#
##########################################################################*/
const char *TString::Find(char ch) const
{
    if (FBuf)
        return strchr(FBuf, ch);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TString::Find
#
#   Purpose....: Find first occurence of a substring, and return string
#
#   In params..: str
#   Out params.: *
#   Returns....: str
#
##########################################################################*/
const char *TString::Find(const char *str) const
{
    if (FBuf)
        return strstr(FBuf, str);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TString::Upper
#
#   Purpose....: Convert to uppercase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TString::Upper(char ch)
{
    return toupper(ch);
}

/*##########################################################################
#
#   Name       : TString::Upper
#
#   Purpose....: Convert to uppercase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Upper()
{
    int i;
    char *ptr;

    FSection.Enter();

    CopyBeforeWrite();

    if (FData)
    {
        ptr = FBuf;
        for (i = 0; i < FData->FDataSize - 1; i++)
        {
            *ptr = Upper(*ptr);
            ptr++;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TString::Lower
#
#   Purpose....: Convert to lowercase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TString::Lower(char ch)
{
    return tolower(ch);
}

/*##########################################################################
#
#   Name       : TString::Lower
#
#   Purpose....: Convert to lowercase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Lower()
{
    int i;
    char *ptr;

    FSection.Enter();

    CopyBeforeWrite();

    if (FData)
    {
        ptr = FBuf;
        for (i = 0; i < FData->FDataSize - 1; i++)
        {
            *ptr = Lower(*ptr);
            ptr++;
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TString::RemoveCrLf
#
#   Purpose....: Remove trailing CR and LF
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::RemoveCrLf()
{
    char *ptr;

    FSection.Enter();

    if (FData)
    {
        ptr = FBuf + FData->FDataSize - 2;
        if (*ptr == 0xd || *ptr == 0xa)
        {
            CopyBeforeWrite();

            while (*ptr == 0xd || *ptr == 0xa)
            {
                *ptr = 0;
                FData->FDataSize--;

                if (ptr == FBuf)
                {
                    Release();
                    break;
                }
                else
                    ptr--;
            }
        }
    }

    FSection.Leave();
}

#ifndef __RDOS__

/*##########################################################################
#
#   Name       : skip_atoi
#
#   Purpose....: Skip atoi
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int skip_atoi(const char **s)
{
    int i = 0;

    while (isdigit(**s))
        i = i*10 + *((*s)++) - '0';
    return i;
}

#endif

/*##########################################################################
#
#   Name       : TString::Append
#
#   Purpose....: Append character
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Append(char ch)
{
    char str[2];

    str[0] = ch;
    str[1] = 0;

    ConcatInPlace(str, 1);
}

/*##########################################################################
#
#   Name       : TString::Append
#
#   Purpose....: Append string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Append(const char *str, int size)
{
    if (size)
    {
        ConcatInPlace(str, size);
        FBuf[FData->FDataSize - 1] = 0;
    }

}

/*##########################################################################
#
#   Name       : TString::ReplaceOne
#
#   Purpose....: Replace one occurence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::ReplaceOne(char *ptr, const char *src, const char *dest)
{
    int srclen = strlen(src);
    int destlen = strlen(dest);
    int i;
    int pos;
    int count;
    char *srcptr;
    char *destptr;
    char *cpyptr;

    if (srclen == destlen)
    {
        for (i = 0; i < destlen; i++)
            ptr[i] = dest[i];
    }
    else
    {
        if (srclen > destlen)
        {
            for (i = 0; i < destlen; i++)
                ptr[i] = dest[i];

            srcptr = ptr + srclen;
            destptr = ptr + destlen;

            while (*srcptr)
            {
                *destptr = *srcptr;
                srcptr++;
                destptr++;
            }
            *destptr = 0;

            FData->FDataSize = FData->FDataSize + destlen - srclen;
        }
        else
        {
            if (FData->FDataSize + destlen - srclen > FData->FAllocSize)
            {
                TShareObjectData* OldData = FData;
                cpyptr = FBuf;
                pos = ptr - FBuf;

                AllocBuffer(OldData->FDataSize + 0x10 + destlen - srclen);
                memcpy(FBuf, cpyptr, OldData->FDataSize);
                FData->FDataSize = OldData->FDataSize;
                Release(OldData);

                ptr = FBuf + pos;
            }

            srcptr = FBuf + FData->FDataSize - 1;
            destptr = srcptr + destlen - srclen;

            count = srcptr - ptr;
            count = count - srclen;
            count++;

            for (i = 0; i < count; i++)
            {
                *destptr = *srcptr;
                srcptr--;
                destptr--;
            }

            for (i = 0; i < destlen; i++)
                ptr[i] = dest[i];

            FData->FDataSize = FData->FDataSize + destlen - srclen;
        }
    }
}

/*##########################################################################
#
#   Name       : TString::Replace
#
#   Purpose....: Replace one string with another
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Replace(const char *src, const char *dest)
{
    char *ptr;
    int pos;

    FSection.Enter();

    if (FData)
    {
        ptr = strstr(FBuf, src);
        while (ptr)
        {
            pos = ptr - FBuf;
            ReplaceOne(ptr, src, dest);
            ptr = FBuf + pos + strlen(dest);
            ptr = strstr(ptr, src);
        }
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TString::Append
#
#   Purpose....: Append string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Append(const char *str)
{
    Append(str, strlen(str));
}

#ifndef __RDOS__

/*##########################################################################
#
#   Name       : TString::Number
#
#   Purpose....: Handle number for printf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::Number(long num, int base, int size, int precision, int type)
{
        char c,sign,tmp[16];
        const char *digits="0123456789abcdefghijklmnopqrstuvwxyz";
        int i, n = 0;
        int ind;

        if (type & LARGE)
                digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

        if (type & LEFT)
                type &= ~ZEROPAD;

        if (base < 2 || base > 36)
                return 0;

        c = (type & ZEROPAD) ? '0' : ' ';
        sign = 0;
        if (type & SIGN)
        {
                if (num < 0)
                {
                        sign = '-';
                        num = -num;
                        size--;
                }
                else
                        if (type & PLUS)
                        {
                                sign = '+';
                                size--;
                        }
                        else
                                if (type & SPACE)
                                {
                                        sign = ' ';
                                        size--;
                                }
        }

        if (type & SPECIAL)
        {
                if (base == 16)
                        size -= 2;

                else if (base == 8)
                        size--;
        }

        i = 0;
        if (num == 0)
                tmp[i++]='0';
        else
                while (num != 0)
                {
                        ind = ((unsigned long)num) % (unsigned)base;
                        num = ((unsigned long)num) / (unsigned)base;
                        tmp[i++] = digits[ind];
                }

        if (i > precision)
                precision = i;

        size -= precision;
        if (!(type&(ZEROPAD+LEFT)))
                while(size-->0)
                {
                        Append(' ');
                        n++;
                }

        if (sign)
        {
                Append(sign);
                n++;
        }

        if (type & SPECIAL)
        {
                if (base==8)
                {
                        Append('0');
                        n++;
                }
                else
                        if (base==16)
                        {
                                Append('0');
                                Append(digits[33]);
                                n += 2;
                        }
                }

        if (!(type & LEFT))
                while (size-- > 0)
                {
                        Append(c);
                        n++;
                }

        while (i < precision--)
        {
                Append('0');
                n++;
        }

        while (i-- > 0)
        {
                Append(tmp[i]);
                n++;
        }

        while (size-- > 0)
        {
                Append(' ');
                n++;
        }

        return n;
}

#endif

/*##########################################################################
#
#   Name       : TString::prtf
#
#   Purpose....: printf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::prtf(const char *fmt, va_list args)
{
    int n;

    FSection.Enter();

    Release();

#ifdef __RDOS__
    n = RdosPrintf(&PrintfCallback, this, fmt, args);
#else

    unsigned long num;
    int i, base;
    const char *s;
    int len;

    int flags;              /* flags to number() */

    int field_width;        /* width of output field */
    int precision;          /* min. # of digits for integers; max
                                   number of chars for from string */
    int qualifier;          /* 'h', 'l', or 'L' for integer fields */
                                /* 'z' support added 23/7/1999 S.H.    */
                                /* 'z' changed to 'Z' --davidm 1/25/99 */


    for (n = 0 ; *fmt ; ++fmt) {
        if (*fmt != '%')
        {
            Append(*fmt);
            n++;
            continue;
        }

        /* process flags */
        flags = 0;
        repeat:
        ++fmt;          /* this also skips first '%' */
        switch (*fmt)
        {
            case '-': flags |= LEFT; goto repeat;
            case '+': flags |= PLUS; goto repeat;
            case ' ': flags |= SPACE; goto repeat;
            case '#': flags |= SPECIAL; goto repeat;
            case '0': flags |= ZEROPAD; goto repeat;
        }

        /* get field width */
        field_width = -1;
        if (isdigit(*fmt))
            field_width = skip_atoi(&fmt);

        else
            if (*fmt == '*')
            {
                ++fmt;
                /* it's the next argument */
                field_width = va_arg(args, int);
                if (field_width < 0)
                {
                    field_width = -field_width;
                    flags |= LEFT;
                }
            }

            /* get the precision */
            precision = -1;
            if (*fmt == '.')
            {
                ++fmt;
                if (isdigit(*fmt))
                    precision = skip_atoi(&fmt);
                else if (*fmt == '*')
                {
                    ++fmt;
                    /* it's the next argument */
                    precision = va_arg(args, int);
                }

                if (precision < 0)
                    precision = 0;
            }

            /* get the conversion qualifier */
            qualifier = -1;
            if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L' || *fmt =='Z')
            {
                qualifier = *fmt;
                ++fmt;
            }

            /* default base */
            base = 10;

            switch (*fmt)
            {
                case 'c':
                    if (!(flags & LEFT))
                        while (--field_width > 0)
                        {
                            Append(' ');
                            n++;
                        }

                        Append((unsigned char) va_arg(args, int));
                        n++;
                        while (--field_width > 0)
                        {
                            Append(' ');
                            n++;
                        }
                        continue;

                case 's':
                    s = va_arg(args, char *);
                    if (!s)
                        s = "<NULL>";

                    len = strlen(s);
                    if (precision != -1 && len > precision)
                        len = precision;

                    if (!(flags & LEFT))
                        while (len < field_width--)
                        {
                            Append(' ');
                            n++;
                        }

                    for (i = 0; i < len; ++i)
                    {
                        Append(*s++);
                        n++;
                    }

                    while (len < field_width--)
                    {
                        Append(' ');
                        n++;
                    }
                    continue;

                case 'p':
                    if (field_width == -1)
                    {
                        field_width = 2*sizeof(void *);
                        flags |= ZEROPAD;
                    }
                    n += Number((unsigned long) va_arg(args, void *), 16,
                    field_width, precision, flags);
                    continue;

                case 'n':
                    if (qualifier == 'l')
                    {
                        long * ip = va_arg(args, long *);
                        *ip = n;
                    }
                    else
                        if (qualifier == 'Z')
                        {
                            size_t * ip = va_arg(args, size_t *);
                            *ip = n;
                        }
                        else
                        {
                            int * ip = va_arg(args, int *);
                            *ip = n;
                        }
                    continue;

                    case '%':
                        Append('%');
                        n++;
                        continue;

                    case 'I':
                        {
                            union
                            {
                                long            l;
                                unsigned char   c[4];
                            } u;

                            u.l = va_arg(args, long);
                            printf("%d.%d.%d.%d", u.c[0], u.c[1], u.c[2], u.c[3]);
                        }
                        continue;

                    /* integer number formats - set up the flags and "break" */
                    case 'o':
                    base = 8;
                        break;

                    case 'X':
                        flags |= LARGE;

                    case 'x':
                        base = 16;
                        break;

                    case 'd':
                    case 'i':
                        flags |= SIGN;

                    case 'u':
                        break;

                    default:
                        Append('%');
                        n++;
                        if (*fmt)
                        {
                            Append(*fmt);
                            n++;
                        }
                        else
                            --fmt;
                            continue;
            }

            if (qualifier == 'L')
                num = va_arg(args, long);
            else
                if (qualifier == 'l')
                {
                    num = va_arg(args, unsigned long);
                    if (flags & SIGN)
                        num = (signed long) num;
                }
                else
                    if (qualifier == 'Z')
                    {
                        num = va_arg(args, size_t);
                    }
                    else
                        if (qualifier == 'h')
                        {
                            num = (unsigned short) va_arg(args, int);
                            if (flags & SIGN)
                                num = (signed short) num;
                        }
                        else
                        {
                            num = va_arg(args, unsigned int);
                            if (flags & SIGN)
                                num = (signed int) num;
                        }

        n += Number(num, base, field_width, precision, flags);
    }
#endif

    FSection.Leave();

    return n;
}

/*##########################################################################
#
#   Name       : TString::printf
#
#   Purpose....: printf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TString::printf(const char *fmt, ...)
{
    va_list args;
    int result;

    FSection.Enter();

    va_start(args, fmt);

#ifdef __RDOS__
    Release();
    result = RdosPrintf(&PrintfCallback, this, fmt, args);
#else
    result = printf(fmt, args);
#endif
    va_end(args);

    FSection.Leave();

    return result;
}
