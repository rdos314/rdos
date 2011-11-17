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
# shareobj.cpp
# Shareable object class
#
########################################################################*/

#if defined __GNUC__ || defined MSVC
#include <string.h>
#else
#include <mem.h>
#endif

#include "shareobj.h"
#include "section.h"

#define FALSE 0
#define TRUE !FALSE

TSection FSection;

/*##########################################################################
#
#   Name       : TShareObject::TShareObject
#
#   Purpose....: Constructor for shareable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShareObject::TShareObject()
{
	Init();
}

/*##########################################################################
#
#   Name       : TShareObject::TShareObject
#
#   Purpose....: Constructor for shareable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShareObject::TShareObject(const void *x, int size)
{
    Init();
    
    AllocBuffer(size);
	memcpy(FBuf, x, size);
}

/*##########################################################################
#
#   Name       : TShareObject::TShareObject
#
#   Purpose....: Copy constructor for shareable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShareObject::TShareObject(const TShareObject &src)
{
    Init();
    
	FData = src.FData;
	if (FData)
	{
		FBuf = src.FBuf;
		src.FData->FRefs++;
	}
}

/*##########################################################################
#
#   Name       : TShareObject::~TShareObject
#
#   Purpose....: Destructor for shareable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShareObject::~TShareObject()
{
    Release();
}

/*##########################################################################
#
#   Name       : TShareObject::Init
#
#   Purpose....: Initialize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::Init()
{
	FBuf = 0;
	FData = 0;
	OnCreate = 0;
}

/*##########################################################################
#
#   Name       : TShareObject::Create
#
#   Purpose....: Create data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShareObjectData *TShareObject::Create(int size)
{
	if (OnCreate)
		return (*OnCreate)(this, size);
    else
    	return (TShareObjectData *)new char[sizeof(TShareObjectData) + size];
}

/*##########################################################################
#
#   Name       : TShareObject::Destroy
#
#   Purpose....: Destroy data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::Destroy(TShareObjectData *obj)
{
	delete obj;
}

/*##########################################################################
#
#   Name       : TShareObject::Load
#
#   Purpose....: Load a new object (for assigment constructors)
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::Load(const TShareObject &src)
{
	if (FBuf != src.FBuf)
	{
		Release();
		FBuf = src.FBuf;
		FData = src.FData;
		if (FData)
			FData->FRefs++;
	}
}

/*##########################################################################
#
#   Name       : TShareObject::GetSize
#
#   Purpose....: Get size of data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::GetSize() const
{
    if (FData)
        return FData->FDataSize;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TShareObject::GetData
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const void *TShareObject::GetData() const
{
    if (FData)
        return FBuf;
    else
        return "";
}

/*##########################################################################
#
#   Name       : TShareObject::SetData
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::SetData(const void *x, int size)
{
	AllocBeforeWrite(size);
	if (size)
	{
		memcpy(FBuf, x, size);
	    FData->FDataSize = size;
	}
	else
		Init();
}

/*##########################################################################
#
#   Name       : TShareObject::AllocBuffer
#
#   Purpose....: Allocate buffer for data
#
#   In params..: size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::AllocBuffer(int size)
{
	if (size == 0)
		Init();
	else
	{
	    FData = Create(size);
		FData->FRefs = 1;
		FData->FDataSize = size;
		FData->FAllocSize = size;
		FBuf = (char *)FData + sizeof(TShareObjectData);
	}
}

/*##########################################################################
#
#   Name       : TShareObject::Release
#
#   Purpose....: Release buffers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::Release()
{
	if (FData)
	{
		FData->FRefs--;
		if (FData->FRefs <= 0)
		    Destroy(FData);
	}
	Init();
}

/*##########################################################################
#
#   Name       : TShareObject::Release
#
#   Purpose....: Release buffers
#
#   In params..: Data
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::Release(TShareObjectData *Data)
{
	if (Data)
	{
        Data->FRefs--;
        if (Data->FRefs <= 0)
            Destroy(Data);
	}
}

/*##########################################################################
#
#   Name       : TShareObject::Empty
#
#   Purpose....: Empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::Empty()
{
	if (FData)
	{
		if (FData->FDataSize)
		{
			if (FData->FRefs >= 0)
				Release();
		}
	}
}

/*##########################################################################
#
#   Name       : TShareObject::CopyBeforeWrite
#
#   Purpose....: Copy data before writing to it
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::CopyBeforeWrite()
{
	TShareObjectData* OldData;
	char* OldBuf;

	if (FData)
	{
		if (FData->FRefs > 1)
		{
			OldData = FData;
			OldBuf = FBuf;
			Release();
			AllocBuffer(OldData->FDataSize);
			memcpy(FBuf, OldBuf, OldData->FDataSize);
		}
	}
}

/*##########################################################################
#
#   Name       : TShareObject::AllocBeforeWrite
#
#   Purpose....: Allocate before writing to it
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::AllocBeforeWrite(int size)
{
    if (FData)
    {
    	if (FData->FRefs > 1 || size > FData->FAllocSize)
	    {
    		Release();
			AllocBuffer(size);
    	}
	}
	else
		if (size)
			AllocBuffer(size);
}

/*##########################################################################
#
#   Name       : TShareObject::AssignCopy
#
#   Purpose....: Assign & copy
#
#   In params..: SrcLen
#				 str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::AssignCopy(const void *x, int size)
{
	AllocBeforeWrite(size);
	if (size)
	{
		memcpy(FBuf, x, size);
		FData->FDataSize = size;
	}
	else
		Init();
}

/*##########################################################################
#
#   Name       : TShareObject::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::Compare(const TShareObject &n2) const
{
	int size;
	int res;
	int size1;
	int size2;

	size1 = FData->FDataSize;
	size2 = n2.FData->FDataSize;

	if (size1 > size2)
		size = size2;
	else
		size = size1;

	res = memcmp(FBuf, n2.FBuf, size);
	if (res == 0)
	{
		if (size1 == size2)
			return 0;
		else
		{
			if (size1 > size2)
				return 1;
			else
				return -1;
		}
	}
	else
		return res;
}

/*##########################################################################
#
#   Name       : TShareObject::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TShareObject &TShareObject::operator=(const TShareObject &src)
{
	if (FBuf != src.FBuf)
	{
		Release();
		FBuf = src.FBuf;
		FData = src.FData;
		if (FData)
			FData->FRefs++;
	}
	return *this;
}

/*##########################################################################
#
#   Name       : TShareObject::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::operator==(const TShareObject &ln) const
{
	if (Compare(ln) == 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TShareObject::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::operator!=(const TShareObject &ln) const
{
	if (Compare(ln) == 0)
		return FALSE;
	else
		return TRUE;
}

/*##########################################################################
#
#   Name       : TShareObject::operator>
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::operator>(const TShareObject &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TShareObject::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::operator<(const TShareObject &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TShareObject::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::operator>=(const TShareObject &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TShareObject::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShareObject::operator<=(const TShareObject &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}
