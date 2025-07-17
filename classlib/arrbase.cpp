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
# arrbase.cpp
# Array base class
#
########################################################################*/

#include <string.h>

#include "arrbase.h"
#include "section.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TArrayBaseNode::TArrayBaseNode
#
#   Purpose....: Constructor for array-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBaseNode::TArrayBaseNode()
{
    FData = 0;
    FValid = FALSE;
}

/*##########################################################################
#
#   Name       : TArrayBaseNode::TArrayBaseNode
#
#   Purpose....: Constructor for array-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBaseNode::TArrayBaseNode(const void *x, int size)
{
    FData = new TShareObject(x, size);
    FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TArrayBaseNode::TArrayBaseNode
#
#   Purpose....: Copy constructor for array-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBaseNode::TArrayBaseNode(const TArrayBaseNode &src)
{
    FData = new TShareObject(*src.FData);
    FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TArrayBaseNode::~TArrayBaseNode
#
#   Purpose....: Destructor for array-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBaseNode::~TArrayBaseNode()
{
    if (FData)
        delete FData;
}

/*##########################################################################
#
#   Name       : TArrayBaseNode::IsValid
#
#   Purpose....: Check if valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TArrayBaseNode::IsValid() const
{
    return FValid;
}

/*##########################################################################
#
#   Name       : TArrayBaseNode::GetSize
#
#   Purpose....: Get size of data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TArrayBaseNode::GetSize() const
{
    if (FData)
        return FData->GetSize();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TArrayBaseNode::GetData
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const void *TArrayBaseNode::GetData() const
{
    if (FData)
        return FData->GetData();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TArrayBaseNode::SetData
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBaseNode::SetData(const void *x, int size)
{
    if (FData)
        FData->SetData(x, size);
    else
        FData = new TShareObject(x, size);

    FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TArrayBase::TArrayBase
#
#   Purpose....: Constructor for array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBase::TArrayBase()
 : FSection("Array Base")
{
    Init();
}

/*##########################################################################
#
#   Name       : TArrayBase::TArrayBase
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBase::TArrayBase(const TArrayBase &src)
 : FSection("Array Base")
{
    int i;
    TArrayBaseNode *p;

    Init();

    FSection.Enter();

    for (i = 0; i < src.FCount; i++)
    {
        p = src.FArr[i];
        Add(src.Clone(p));
    }
        
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TArrayBase::~TArrayBase
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBase::~TArrayBase()
{
    Clear();
}

/*##########################################################################
#
#   Name       : TArrayBase::Init
#
#   Purpose....: Init list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Init()
{
    FArr = 0;
    FCount = 0;
    FAllocSize = 0;
}

/*##########################################################################
#
#   Name       : TArrayBase::Get
#
#   Purpose....: Get element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBaseNode *TArrayBase::Get(int pos)
{
    TArrayBaseNode *p;

    FSection.Enter();

    if (pos < FCount && pos >= 0)
        p = FArr[pos];
    else
        p = 0;
    
    FSection.Leave();

    return p;
}

/*##########################################################################
#
#   Name       : TArrayBase::Load
#
#   Purpose....: Load with other object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Load(const TArrayBase &src)
{
    TArrayBaseNode *p;
    int i;
    
    Clear();    

    FSection.Enter();

    for (i = 0; i < src.FCount; i++)
    {
        p = src.FArr[i];
        Add(src.Clone(p));
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TArrayBase::Clear
#
#   Purpose....: Clear list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Clear()
{
    int i;
    TArrayBaseNode *p;

    FSection.Enter();

    for (i = 0; i < FCount; i++)
    {
        p = FArr[i];

        if (p)
            delete p;
        
        FArr[i] = 0;
    }

    delete FArr;

    Init();

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TArrayBase::Grow
#
#   Purpose....: Grow array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Grow()
{
    int i;
    int newsize;
    TArrayBaseNode **newarr;

    if (FAllocSize)
    {
        newsize = 3 * FAllocSize / 2;
        newarr = new TArrayBaseNode *[newsize];

        for (i = 0; i < FCount; i++)
            newarr[i] = FArr[i];

        for (i = FCount; i < newsize; i++)
            newarr[i] = 0;

        delete FArr;

        FArr = newarr;
        FAllocSize = newsize;
    }
    else
    {
        FAllocSize = 16;
        FArr = new TArrayBaseNode *[FAllocSize];

        for (i = 0; i < FAllocSize; i++)
            FArr[i] = 0;
    }
}

/*##########################################################################
#
#   Name       : TArrayBase::IsEmpty
#
#   Purpose....: Check if array is empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TArrayBase::IsEmpty()
{
    if (FCount)
        return FALSE;
    else
        return TRUE;
}

/*##########################################################################
#
#   Name       : TArrayBase::GetSize
#
#   Purpose....: Get # of elements in array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TArrayBase::GetSize()
{
    return FCount;
}

/*##########################################################################
#
#   Name       : TArrayBase::Add
#
#   Purpose....: Add entry last
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Add(TArrayBaseNode *p)
{
    FSection.Enter();

    while (FCount >= FAllocSize)
        Grow();

    FArr[FCount] = p;
    FCount++;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TArrayBase::Add
#
#   Purpose....: Add entry at specified position.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Add(int pos, TArrayBaseNode *p)
{
    int i;

    if (pos < 0)
        return;

    if (pos >= FCount)
        Add(p);
    else
    {
        FSection.Enter();

        while (FCount >= FAllocSize)
            Grow();

        for (i = FCount; i > pos; i--)
            FArr[i] = FArr[i - 1];

        FArr[pos] = p;
        FCount++;

        FSection.Leave();
    }
}

/*##########################################################################
#
#   Name       : TArrayBase::Remove
#
#   Purpose....: Remove last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Remove()
{
    TArrayBaseNode *p;

    FSection.Enter();

    if (FCount)
    {
        FCount--;

        p = FArr[FCount];

        if (p)
            delete p;
        
        FArr[FCount] = 0;
    }

    if (FCount == 0)        
    {
        delete FArr;
        FArr = 0;
        FAllocSize = 0;
    }
        
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TArrayBase::Remove
#
#   Purpose....: Remove specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Remove(int pos)
{
    int i;
    TArrayBaseNode *p;

    if (pos < 0)
        return;

    if (pos >= FCount)
        return;

    FSection.Enter();

    p = FArr[pos];

    if (p)
        delete p;

    for (i = pos + 1; i < FCount; i++)
        FArr[i - 1] = FArr[i];

    FCount--;
        
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TArrayBase::Replace
#
#   Purpose....: Replace specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Replace(int pos, const TArrayBaseNode *newln)
{
    if (pos < 0)
        return;

    if (pos >= FCount)
        return;

    FSection.Enter();

    if (FArr[pos])
        FArr[pos]->Load(*newln);
        
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TArrayBase::Concat
#
#   Purpose....: Concat in this list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TArrayBase::Concat(const TArrayBase &src1, const TArrayBase& src2)
{
    int i;
    TArrayBaseNode *p;

    Clear();

    FSection.Enter();

    for (i = 0; i < src1.FCount; i++)
    {
        p = src1.FArr[i];
        Add(src1.Clone(p));
    }

    for (i = 0; i < src2.FCount; i++)
    {
        p = src2.FArr[i];
        Add(src2.Clone(p));
    }

    FSection.Leave();
}
