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
# list.cpp
# List class
#
########################################################################*/

#include <mem.h>

#include "list.h"
#include "section.h"

#define FALSE 0
#define TRUE !FALSE

TSection FSection;
TListNode EmptyList;


/*##########################################################################
#
#   Name       : TListNode::TListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode::TListNode()
{
	Init();
	FValid = FALSE;
}

/*##########################################################################
#
#   Name       : TListNode::TListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode::TListNode(const void *x, int size)
{
    Init();
    
    AllocBuffer(size);
	memcpy(FBuf, x, size);
	FNext = 0;

	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TListNode::TListNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode::TListNode(const TListNode &src)
{
    Init();
    
	FData = src.FData;
	if (FData)
	{
		FBuf = src.FBuf;
		src.FData->FRefs++;
	}
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TListNode::~TListNode
#
#   Purpose....: Destructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode::~TListNode()
{
    Release();
}

/*##########################################################################
#
#   Name       : TListNode::Init
#
#   Purpose....: Initialize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::Init()
{
	FBuf = 0;
	FData = 0;
}

/*##########################################################################
#
#   Name       : TListNode::IsValid
#
#   Purpose....: Check if valid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::IsValid() const
{
	return FValid;
}

/*##########################################################################
#
#   Name       : TListNode::GetSize
#
#   Purpose....: Get size of data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::GetSize() const
{
    if (FValid && FData)
        return FData->FDataSize;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TListNode::GetData
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const void *TListNode::GetData() const
{
    if (FValid && FData)
        return FBuf;
    else
        return "";
}

/*##########################################################################
#
#   Name       : TListNode::SetData
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::SetData(const void *x, int size)
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
#   Name       : TListNode::AllocBuffer
#
#   Purpose....: Allocate buffer for data
#
#   In params..: size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::AllocBuffer(int size)
{
	if (size == 0)
		Init();
	else
	{
		FData = (TListData *)new char[sizeof(TListData) + size];
		FData->FRefs = 1;
		FData->FDataSize = size;
		FData->FAllocSize = size;
		FBuf = (char *)FData + sizeof(TListData);
	}
}

/*##########################################################################
#
#   Name       : TListNode::Release
#
#   Purpose....: Release buffers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::Release()
{
	if (FData)
	{
		FData->FRefs--;
		if (FData->FRefs <= 0)
			delete FData;
	}
	Init();
}

/*##########################################################################
#
#   Name       : TListNode::Release
#
#   Purpose....: Release buffers
#
#   In params..: Data
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::Release(TListData *Data)
{
	if (Data)
	{
        Data->FRefs--;
        if (Data->FRefs <= 0)
            delete Data;
	}
}

/*##########################################################################
#
#   Name       : TListNode::Empty
#
#   Purpose....: Empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::Empty()
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
#   Name       : TListNode::CopyBeforeWrite
#
#   Purpose....: Copy data before writing to it
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::CopyBeforeWrite()
{
	TListData* OldData;
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
#   Name       : TListNode::AllocBeforeWrite
#
#   Purpose....: Allocate before writing to it
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::AllocBeforeWrite(int size)
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
#   Name       : TListNode::AssignCopy
#
#   Purpose....: Assign & copy
#
#   In params..: SrcLen
#				 str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::AssignCopy(const void *x, int size)
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
#   Name       : TListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::Compare(const TListNode &n2) const
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
#   Name       : TListNode::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode *TListNode::Clone()
{
	if (FData)
	{
		FData->FRefs++;
	    return new TListNode(FBuf, FData->FDataSize);
    }
    else
        return new TListNode(0, 0);
}

/*##########################################################################
#
#   Name       : TListNode::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TListNode &TListNode::operator=(const TListNode &src)
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
#   Name       : TListNode::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::operator==(const TListNode &ln) const
{
	if (Compare(ln) == 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TListNode::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::operator!=(const TListNode &ln) const
{
	if (Compare(ln) == 0)
		return FALSE;
	else
		return TRUE;
}

/*##########################################################################
#
#   Name       : TListNode::operator>
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::operator>(const TListNode &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TListNode::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::operator<(const TListNode &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TListNode::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::operator>=(const TListNode &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TListNode::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TListNode::operator<=(const TListNode &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TNode::TNode
#
#   Purpose....: Constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList::TList()
{
    Init();
}

/*##########################################################################
#
#   Name       : TList::TList
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList::TList(const TList &src)
{
    TListNode *p;

    Init();

    FSection.Enter();
    p = src.FList;

    while (p)
    {
        AddLast(*p->Clone());
        p = p->FNext;
    }
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::~TList
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList::~TList()
{
    Clear();
}

/*##########################################################################
#
#   Name       : TList::Init
#
#   Purpose....: Init list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Init()
{
    FList = 0;
    FCurrPos = 0;
    FPrevPos = 0;
}

/*##########################################################################
#
#   Name       : TList::Compare
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::Compare(const TList &l) const
{
	TListNode *p1;
	TListNode *p2;
	int res;

	FSection.Enter();

	if (this == &l)
		res = 0;
	else
	{
		p1 = FList;
		p2 = l.FList;

		if (p1 && p2)
		{
			while (p1 && p2)
			{
				if (p1 == p2)
				{
					res = 0;
					break;
				}
				else
				{
				    res = p1->Compare(*p2);				    
					if (res != 0)
						break;
				}
				p1 = p1->FNext;
				p2 = p2->FNext;
			}
		}
		else
		{
			if (p1 == 0 && p2 == 0)
				res = 0;
			else
			{
			    if (p1)
			        res = 1;
			    else
			        res = -1;
			}
		}
	}
	FSection.Leave();

	return res;
}

/*##########################################################################
#
#   Name       : TList::operator==
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::operator==(const TList &l) const
{
    if (Compare(l) == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TList::operator!=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::operator!= (const TList &l) const
{
    if (Compare(l) != 0)
        return TRUE;
    else
        return FALSE;
}    

/*##########################################################################
#
#   Name       : TList::operator>
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::operator>(const TList &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TList::operator<
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::operator<(const TList &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TList::operator>=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::operator>=(const TList &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TList::operator<=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::operator<=(const TList &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TList::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList &TList::operator=(const TList &src)
{
    TListNode *p;
    
    Clear();    

    FSection.Enter();

    if (FList != src.FList)
    {
        p = src.FList;

        while (p)
        {
            AddLast(*p->Clone());
            p = p->FNext;
        }
    }

    FSection.Leave();

    return *this;
}

/*##########################################################################
#
#   Name       : TList::operator+=
#
#   Purpose....: Concat operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList &TList::operator+=(const TList &l)
{
	TList list;
	list.Concat(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TList::operator&=
#
#   Purpose....: Intersec operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList &TList::operator&=(const TList &l)
{
	TList list;
	list.Intersect(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TList::operator|=
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList &TList::operator|=(const TList &l)
{
	TList list;
	list.Union(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TList::operator^=
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList &TList::operator^=(const TList &l)
{
	TList list;
	list.Difference(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TList::operator[]
#
#   Purpose....: Vector operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode &TList::operator[](int pos)
{
    TListNode *p;
    int n = 0;

    FSection.Enter();
    
    if (FList)
    {
        p = FList;

        while (p && n < pos)
        {
            p = p->FNext;
            n++;
        }
    }

    FSection.Leave();

    if (p)
        return *p;
    else
        return EmptyList;
}

/*##########################################################################
#
#   Name       : TList::Clear
#
#   Purpose....: Clear list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Clear()
{
    TListNode *p;

    FSection.Enter();

    while (FList)
    {
        p = FList;
        FList = FList->FNext;
        delete p;
    }
    Init();

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::IsEmpty
#
#   Purpose....: Check if list is empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::IsEmpty()
{
    if (FList)
        return FALSE;
    else
        return TRUE;
}

/*##########################################################################
#
#   Name       : TList::Invalidate
#
#   Purpose....: Invalidate pointers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Invalidate(TListNode *ln)
{
    if (FCurrPos == ln)
        FCurrPos = 0;

    if (FPrevPos == ln)
        FPrevPos = 0;
}

/*##########################################################################
#
#   Name       : TList::GetSize
#
#   Purpose....: Get # of elements in list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::GetSize()
{
    int n = 0;
    TListNode *p;

    FSection.Enter();

    p = FList;

    while (p)
    {
        n++;
        p = p->FNext;
    }

    FSection.Leave();    

    return n;
}

/*##########################################################################
#
#   Name       : TList::GetPosition
#
#   Purpose....: Get current position in list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::GetPosition()
{
    int n = 0;
    TListNode *p;

    FSection.Enter();

    p = FList;

	if (FCurrPos)
    {
        while (p && p != FCurrPos)
		{
            n++;
            p = p->FNext;
        }
    }

    FSection.Leave();    

    return n;
}

/*##########################################################################
#
#   Name       : TList::GotoFirst
#
#   Purpose....: Goto first element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::GotoFirst()
{
    FSection.Enter();
    FCurrPos = FList;
    FPrevPos = 0;
    FSection.Leave();
    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TList::GotoNext
#
#   Purpose....: Goto next element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::GotoNext()
{
    FSection.Enter();

    if (FCurrPos)
        FCurrPos = FCurrPos->FNext;

    FSection.Leave();

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TList::GotoPrev
#
#   Purpose....: Goto previous element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::GotoPrev()
{
    TListNode *p;
    
    FSection.Enter();

    if (FPrevPos && FPrevPos->FNext == FCurrPos)
    {
        FCurrPos = FPrevPos;
        FPrevPos = 0;
    }
    else
    {
        FPrevPos = 0;
		p = FList;

        while (p && p->FNext != FCurrPos) 
		{
            FPrevPos = p;
            p = p->FNext;
        }
        FCurrPos = p;
    }       

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TList::GotoLast
#
#   Purpose....: Goto last element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::GotoLast()
{
    FSection.Enter();

    FPrevPos = 0;
    FCurrPos = FList;

    while (FCurrPos && FCurrPos->FNext) 
    {
        FPrevPos = FCurrPos;
        FCurrPos = FCurrPos->FNext;
    }

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TList::Goto
#
#   Purpose....: Goto n:th element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::Goto(int pos)
{
    int n = 0;

    FSection.Enter();

    FCurrPos = FList;

	while (FCurrPos && n < pos)
    {
        n++;
		FCurrPos = FCurrPos->FNext;
    }

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TList::Find
#
#   Purpose....: Find specific data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::Find(const TListNode &ln)
{
    FSection.Enter();

    FCurrPos = FList;

	while (FCurrPos && *FCurrPos != ln)
		FCurrPos = FCurrPos->FNext;

    FSection.Leave();    

    return FCurrPos != 0;
}

/*##########################################################################
#
#   Name       : TList::Get
#
#   Purpose....: Get current data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode &TList::Get()
{
	if (FCurrPos)
		return *FCurrPos;
	else
		return EmptyList;
}

/*##########################################################################
#
#   Name       : TList::AddFirst
#
#   Purpose....: Add entry as first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::AddFirst(TListNode &newln)
{
    TListNode *p;

    FSection.Enter();
    p = new TListNode(newln);
    p->FNext = FList;
    FList = p;
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::AddLast
#
#   Purpose....: Add entry as last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::AddLast(TListNode &newln)
{
    TListNode *p;
    TListNode *tp;

    FSection.Enter();
    p = new TListNode(newln);

    if (FList)
    {
        tp = FList;
        while (tp->FNext)
            tp = tp->FNext;

        tp->FNext = p;
    }
    else
        FList = p;
        
    p->FNext = 0;
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::AddAt
#
#   Purpose....: Add entry at specified position, if possible.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::AddAt(int n, TListNode &newln)
{
    TListNode *p;
    TListNode *tp;
    int pos = 0;

    FSection.Enter();
    p = new TListNode(newln);

    if (FList)
    {
        tp = FList;
        while (tp->FNext && pos < n)
        {
            pos++;
            tp = tp->FNext;
        }

        if (tp->FNext)
        {
            p->FNext = tp->FNext;
            tp->FNext = p;
        }
        else
        {
            tp->FNext = p;
            p->FNext = 0;
        }
    }
    else
    {
        FList = p;
        p->FNext = 0;
    }
    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::RemoveFirst
#
#   Purpose....: Remove first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::RemoveFirst()
{
    int success;
    TListNode *p;

    FSection.Enter();

    if (FList)
    {
        p = FList;
        FList = FList->FNext;
        Invalidate(p);
        delete p;
        success = TRUE;

    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TList::RemoveLast
#
#   Purpose....: Remove last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::RemoveLast()
{
    int success;
    TListNode *p;
    TListNode *prev;

    FSection.Enter();

    if (FList)
    {
        prev = 0;
        p = FList;
        while (p->FNext)
        {
            prev = p;
            p = p->FNext;
        }

        if (prev)
            prev->FNext = 0;    
        else
            FList = 0;

        Invalidate(p);
        delete p;
        
        success = TRUE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TList::RemoveCurrent
#
#   Purpose....: Remove current entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::RemoveCurrent()
{
    int success;
    TListNode *p;
    TListNode *prev;

    FSection.Enter();

    if (FList && FCurrPos)
    {
        prev = 0;
        p = FList;
        while (p && p->FNext != FCurrPos)
        {
            prev = p;
            p = p->FNext;
        }

        if (p)
        {
            if (prev)
                prev->FNext = p->FNext;    
            else
                FList = p->FNext;

            Invalidate(p);
            delete p;
            
            success = TRUE;
        }
        else
            success = FALSE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TList::Remove
#
#   Purpose....: Remove specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::Remove(int pos)
{
    int success;
    TListNode *p;
    TListNode *prev;
    int n = 0;

    FSection.Enter();

    if (FList)
    {
        prev = 0;
        p = FList;
        while (p && n < pos)
        {
            n++;
            prev = p;
            p = p->FNext;
        }

        if (p)
        {
            if (prev)
                prev->FNext = p->FNext;    
            else
                FList = p->FNext;

            Invalidate(p);
            delete p;
            
            success = TRUE;
        }
        else
            success = FALSE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TList::Replace
#
#   Purpose....: Replace specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::Replace(int pos, TListNode &newln)
{
    int success;
    TListNode *p;
    int n = 0;

    FSection.Enter();

    if (FList)
    {
        p = FList;
        while (p && n < pos)
        {
            n++;
            p = p->FNext;
        }

        if (p)
        {
            *p = newln;
            success = TRUE;
        }
        else
            success = FALSE;
    }
    else
        success = FALSE;
        
    FSection.Leave();

    return success;
}

/*##########################################################################
#
#   Name       : TList::Concat
#
#   Purpose....: Concat in this list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Concat(const TList &list1, const TList& list2)
{
	TListNode *p;

    Clear();
    FSection.Enter();

    p = list1.FList;

    while (p)
    {
        AddLast(*p->Clone());
        p = p->FNext;
    }

    p = list2.FList;

    while (p)
    {
        AddLast(*p->Clone());
        p = p->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::Intersect
#
#   Purpose....: Intersection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Intersect(const TList &list1, const TList& list2)
{
	TListNode *p1;
	TListNode *p2;

    Clear();
    FSection.Enter();

    p1 = list1.FList;

    while (p1)
    {

        p2 = list2.FList;

    	while (p2 && *p1 != *p2)
    	    p2 = p2->FNext;

        if (p2)
            AddLast(*p1->Clone());
            
        p1 = p1->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::Union
#
#   Purpose....: Union
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Union(const TList &list1, const TList& list2)
{
	TListNode *p1;
	TListNode *p2;

    Clear();

    FSection.Enter();

    p1 = list1.FList;

    while (p1)
    {
        AddLast(*p1->Clone());
        p1 = p1->FNext;
    }

    p2 = list2.FList;

    while (p2)
    {

        p1 = list1.FList;

    	while (p1 && *p1 != *p2)
    	    p1 = p1->FNext;

        if (!p1)
            AddLast(*p2->Clone());
            
        p2 = p2->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::Difference
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Difference(const TList &list1, const TList& list2)
{
	TListNode *p1;
	TListNode *p2;

    Clear();

    FSection.Enter();

    p1 = list1.FList;

    while (p1)
    {

        p2 = list2.FList;

    	while (p2 && *p1 != *p2)
    	    p2 = p2->FNext;

        if (!p2)
            AddLast(*p1->Clone());
            
        p1 = p1->FNext;
    }

    p2 = list2.FList;

    while (p2)
    {

        p1 = list1.FList;

    	while (p1 && *p1 != *p2)
    	    p1 = p1->FNext;

        if (!p1)
            AddLast(*p2->Clone());
            
        p2 = p2->FNext;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::Reverse
#
#   Purpose....: Reverse list in place
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Reverse()
{
    TListNode *p;
    TListNode *tp;

    FSection.Enter();

    p = FList;
    Init();

    while (p)
    {
        tp = p->FNext;
        p->FNext = FList;
        FList = p;
        p = tp;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TList::RemoveDuplicates
#
#   Purpose....: Remove duplicates from list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::RemoveDuplicates()
{
    TListNode *p;
    TListNode *tp;
    TListNode *insp;
    TListNode *np;

    FSection.Enter();

    p = FList;
    Init();
    insp = 0;

    while (p)
    {
        np = p->FNext;
        
        tp = FList;
    	while (tp && *tp != *p)
    		tp = tp->FNext;

        if (tp)
            delete p;
        else
        {
            if (insp)
            {
                insp->FNext = p;
                p->FNext = 0;
            }
            else
                FList = p;
                
            insp = p;
        }

        p = np;
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList operator+(const TList &list1, const TList& list2)
{
	TList list;
    list.Concat(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : TList::operator&
#
#   Purpose....: Intersection operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList operator&(const TList &list1, const TList& list2)
{
	TList list;
    list.Intersect(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : TList::operator|
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList operator|(const TList &list1, const TList& list2)
{
	TList list;
    list.Union(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : TList::operator^
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TList operator^(const TList &list1, const TList& list2)
{
	TList list;
    list.Difference(list1, list2);
    return list;
}
