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
# shareobj.cpp
# Shareable object class
#
########################################################################*/

#include <string.h>

#include "shareobj.h"

#define FALSE 0
#define TRUE !FALSE

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
 : FSection("ShareObj")
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
 : FSection("ShareObj")
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
 : FSection("ShareObj")
{
    Init();

    src.FSection.Enter();
    
    FData = src.FData;
    if (FData)
    {
        FBuf = src.FBuf;
        src.FData->FRefs++;
    }

    src.FSection.Leave();
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
    FSection.Enter();
    Release();
    FSection.Leave();
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
    src.FSection.Enter();
    FSection.Enter();

    if (FBuf != src.FBuf)
    {
        Release();
        FBuf = src.FBuf;
        FData = src.FData;
        if (FData)
            FData->FRefs++;
    }

    FSection.Leave();
    src.FSection.Leave();
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
    int size = 0;

    FSection.Enter();
    
    if (FData)
        size = FData->FDataSize;

    FSection.Leave();

    return size;
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
    void *data = "";

    FSection.Enter();
    
    if (FData)
        data = FBuf;

    FSection.Leave();

    return data;
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
    FSection.Enter();
    
    AllocBeforeWrite(size);
    if (size)
    {
        memcpy(FBuf, x, size);
        FData->FDataSize = size;
    }

    FSection.Leave();
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
    FSection.Enter();

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

    FSection.Leave();
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
    FSection.Enter();

    if (FData)
    {
        FData->FRefs--;
        if (FData->FRefs <= 0)
            Destroy(FData);
    }
    Init();

    FSection.Leave();
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
    FSection.Enter();
    
    if (Data)
    {
        Data->FRefs--;
        if (Data->FRefs <= 0)
            Destroy(Data);
    }

    FSection.Leave();
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
    FSection.Enter();
    
    if (FData)
    {
        if (FData->FDataSize)
        {
            if (FData->FRefs >= 0)
                Release();
        }
    }

    FSection.Leave();
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

    FSection.Enter();

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

    FSection.Leave();
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
    FSection.Enter();
    
    if (FData)
    {
        if (size == 0)
            Release();
        else
        {
            if (FData->FRefs > 1 || size > FData->FAllocSize)
            {
                Release();
                AllocBuffer(size);
            }
        }
    }
    else
        if (size)
            AllocBuffer(size);

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TShareObject::AssignCopy
#
#   Purpose....: Assign & copy
#
#   In params..: SrcLen
#                str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShareObject::AssignCopy(const void *x, int size)
{
    FSection.Enter();

    AllocBeforeWrite(size);
    if (size)
    {
        memcpy(FBuf, x, size);
        FData->FDataSize = size;
    }

    FSection.Leave();
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
    int ret;
    int size1;
    int size2;

    n2.FSection.Enter();
    FSection.Enter();

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
            ret = 0;
        else
        {
            if (size1 > size2)
                ret = 1;
            else
                ret =  -1;
        }
    }
    else
        ret = res;

    FSection.Leave();
    n2.FSection.Leave();

    return ret;
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
    src.FSection.Enter();
    FSection.Enter();
    
    if (FBuf != src.FBuf)
    {
        
        Release();
        FBuf = src.FBuf;
        FData = src.FData;
        if (FData)
            FData->FRefs++;

    }
    
    FSection.Leave();
    src.FSection.Leave();
    
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
