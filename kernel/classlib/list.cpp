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
    AllocBuffer(size);
	memcpy(FBuf, x, size);
	FRefCount = 1;
	FNext = 0;

    Init();
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
#   Name       : TList::operator==
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TList::operator== (const TList &l) const
{
	TListNode *p1;
	TListNode *p2;
	int res;

	FSection.Enter();

	if (this == &l)
		res = TRUE;
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
					res = TRUE;
					break;
				}
				else
				{
					if (p1->Compare(*p2) != 0)
					{
						res = FALSE;
						break;
					}
				}
				p1 = p1->FNext;
				p2 = p2->FNext;
			}
		}
		else
		{
			if (p1 == 0 && p2 == 0)
				res = TRUE;
			else
				res = FALSE;
		}
	}
	FSection.Leave();

	return res;
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
    TListNode *p1;
    TListNode *p2;
    int res;

    FSection.Enter();
    
    if (this == &l)
        res = FALSE;
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
                    res = FALSE;
                    break;
                }
                else
                {
					if (p1->Compare(*p2) != 0)
                    {
                        res = TRUE;
                        break;
                    }
                }
                p1 = p1->FNext;
				p2 = p2->FNext;
            }
        }
		else
        {
            if (p1 == 0 && p2 == 0)        
                res = FALSE;
            else
                res = TRUE;
        }
    }
    FSection.Leave();

    return res;
}    

/*##########################################################################
#
#   Name       : TList::Reference
#
#   Purpose....: Increment reference count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Reference(TListNode *n)
{
    if (n)
        n->FRefCount++;
}

/*##########################################################################
#
#   Name       : TList::Dereference
#
#   Purpose....: Decrement reference count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TList::Dereference(TListNode *n)
{
    if (n)
    {
        n->FRefCount--;
        if (n->FRefCount <= 0)
            FreeNodes(n);
    }
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
    FSection.Enter();

    FCurrPos = 0;
    FPrevPos = 0;
    Dereference(FList);
    FList = 0;

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
    TListNode *p;

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
