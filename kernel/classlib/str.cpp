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

#include "str.h"
#include "section.h"

TSection Section;

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
	Init();
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
{
	Section.Enter();
	FData = src.FData;
	FBuf = src.FBuf;
    src.FData->FRefs++;
	Section.Leave();
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
{
	int len;

	Init();

	if (str)
	{
		len = strlen(str);
		if (len)
		{
			AllocBuffer(len);
			memcpy(FBuf, str, len);
		}
	}
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
	Section.Enter();
	if (FData)
	{
        FData->FRefs--;
        if (FData->FRefs <= 0)
            delete FData;
	}
	Section.Leave();
}

/*##########################################################################
#
#   Name       : TString::Init
#
#   Purpose....: Initialize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Init()
{
	FBuf = 0;
	FData = 0;
}

/*##########################################################################
#
#   Name       : TString::AllocBuffer
#
#   Purpose....: Allocate buffer for data
#
#   In params..: size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::AllocBuffer(int size)
{
	if (size == 0)
		Init();
	else
	{
		Section.Enter();
		FData = (TStringData *)new char[sizeof(TStringData) + size + 1];
		FData->FRefs = 1;
		FData->FDataSize = size;
		FData->FAllocSize = size;
		FBuf = (char *)FData + sizeof(TStringData);
		*(FBuf+size) = 0;
		Section.Leave();
	}
}

/*##########################################################################
#
#   Name       : TString::Release
#
#   Purpose....: Release buffers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Release()
{
	Section.Enter();
	FData->FRefs--;
	if (FData->FRefs <= 0)
    	delete FData;
	Init();
	Section.Leave();
}

/*##########################################################################
#
#   Name       : TString::Release
#
#   Purpose....: Release buffers
#
#   In params..: Data
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Release(TStringData *Data)
{
	Section.Enter();
	if (Data)
	{
        Data->FRefs--;
        if (Data->FRefs <= 0)
            delete Data;
	}
	Section.Leave();
}

/*##########################################################################
#
#   Name       : TString::Empty
#
#   Purpose....: Empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::Empty()
{
	if (FData->FDataSize)
	{
		if (FData->FRefs >= 0)
			Release();
	}
}

/*##########################################################################
#
#   Name       : TString::CopyBeforeWrite
#
#   Purpose....: Copy string before writing to it
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::CopyBeforeWrite()
{
	TStringData* OldData;
	char* OldBuf;

	if (FData->FRefs > 1)
	{
		OldData = FData;
		OldBuf = FBuf;
		Release();
		AllocBuffer(FData->FDataSize);
		memcpy(FBuf, OldBuf, OldData->FDataSize+1);
	}
}

/*##########################################################################
#
#   Name       : TString::AllocBeforeWrite
#
#   Purpose....: Allocate before writing to it
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::AllocBeforeWrite(int size)
{
	if (FData->FRefs > 1 || size > FData->FAllocSize)
	{
		Release();
		AllocBuffer(size);
	}
}

/*##########################################################################
#
#   Name       : TString::AllocCopy
#
#   Purpose....: Allocate a copy
#
#   In params..: dest
#				 CopyLen
#				 CopyIndex
#				 ExtraLen
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::AllocCopy(TString& dest, int CopyLen, int CopyIndex, int ExtraLen) const
{
	int NewLen = CopyLen + ExtraLen;

	if (NewLen == 0)
		dest.Init();
	else
	{
		dest.AllocBuffer(NewLen);
		memcpy(dest.FBuf, FBuf+CopyIndex, CopyLen);
	}
}

/*##########################################################################
#
#   Name       : TString::AssignCopy
#
#   Purpose....: Assign & copy
#
#   In params..: SrcLen
#				 str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::AssignCopy(int len, const char *str)
{
	AllocBeforeWrite(len);
	memcpy(FBuf, str, len);
	FData->FDataSize = len;
	*(FBuf+len) = 0;
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
	if (FBuf != src.FBuf)
	{
		Release();
		FBuf = src.FBuf;
        FData = src.FData;
		FData->FRefs++;
	}
	return *this;
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
	AssignCopy(strlen(str), str);
	return *this;
}

/*##########################################################################
#
#   Name       : TString::ConcatCopy
#
#   Purpose....: Concat strings
#
#   In params..: len1
#				 str1
#				 len2
#				 str2
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::ConcatCopy(int len1, const char *str1, int len2, const char *str2)
{
	int NewLen = len1 + len2;

	if (NewLen)
	{
		AllocBuffer(NewLen);
		memcpy(FBuf, str1, len1);
		memcpy(FBuf+len1, str2, len2);
	}
}

/*##########################################################################
#
#   Name       : operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: str1
#				 str2
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString operator+(const TString& str1, const TString& str2)
{
	TString s;
	s.ConcatCopy(str1.GetSize(), str1.GetData(), str2.GetSize(), str2.GetData());
	return s;
}

/*##########################################################################
#
#   Name       : TString::operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: str
#				 cstr
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString operator+(const TString& str, const char *cstr)
{
	TString s;
	s.ConcatCopy(str.GetSize(), str.GetData(), strlen(cstr), cstr);
	return s;
}

/*##########################################################################
#
#   Name       : TString::operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: cstr
#				 str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString operator+(const char *cstr, const TString& str)
{
	TString s;
	s.ConcatCopy(strlen(cstr), cstr, str.GetSize(), str.GetData());
	return s;
}

/*##########################################################################
#
#   Name       : TString::ConcatInPlace
#
#   Purpose....: Concatenation in place
#
#   In params..: len
#				 str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TString::ConcatInPlace(int len, const char *str)
{
	if (len)
	{
		if (FData->FRefs > 1 || FData->FDataSize + len > FData->FAllocSize)
		{
			TStringData* OldData = FData;
			ConcatCopy(FData->FDataSize, FBuf, len, str);
			Release(OldData);
		}
		else
		{
			memcpy(FBuf+FData->FDataSize, str, len);
			FData->FDataSize += len;
			*(FBuf+FData->FDataSize) = 0;
		}
	}
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
	ConcatInPlace(strlen(str), str);
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
	ConcatInPlace(1, &ch);
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
	ConcatInPlace(str.FData->FDataSize, str.FBuf);
	return *this;
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
	if (FData)
		return FData->FDataSize;
	else
		return 0;
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

	CopyBeforeWrite();

	if (FData)
	{
		ptr = FBuf;
		for (i = 0; i < FData->FDataSize; i++)
		{
			*ptr = Upper(*ptr);
			ptr++;
		}
	}
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

	CopyBeforeWrite();

	if (FData)
	{
		ptr = FBuf;
		for (i = 0; i < FData->FDataSize; i++)
		{
			*ptr = Lower(*ptr);
			ptr++;
		}
	}
}
