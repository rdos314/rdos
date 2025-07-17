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
# list.cpp
# List class
#
########################################################################*/

#include <string.h>

#include "list.h"
#include "section.h"

#define FALSE 0
#define TRUE !FALSE

static TListNode EmptyList;

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
  : TListBaseNode(x, size)
{
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
  : TListBaseNode(src)
{
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
    if (FData && n2.FData)
        return FData->Compare(*n2.FData);
    else
    {
        if (FData || n2.FData)
        {
            if (FData)
                return 1;
            else
                return -1;
        }
        else
            return 0;
    }
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
int TListNode::Compare(const TListBaseNode &n2) const
{
    TListNode *p = (TListNode *)&n2;
    return Compare(*p);    
}

/*##########################################################################
#
#   Name       : TListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::Load(const TListNode &src)
{
    if (FData)
        *FData = *src.FData;
    else
    {
        if (src.FData)
            FData = new TShareObject(*src.FData);
    }
    FValid = src.FValid;
}

/*##########################################################################
#
#   Name       : TListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TListNode::Load(const TListBaseNode &src)
{
    TListNode *p = (TListNode *)&src;
    Load(*p);
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
    Load(src);
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
#   Name       : TList::TList
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
  : TListBase(src)
{
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
}

/*##########################################################################
#
#   Name       : TList::Clone
#
#   Purpose....: Clone list node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListNode *TList::Clone(const TListNode *ln) const
{
    return new TListNode(*ln);
}

/*##########################################################################
#
#   Name       : TList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode *TList::Clone(const TListBaseNode *ln) const
{
    TListNode *p = (TListNode *)ln;
    return new TListNode(*p);
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
    Load(src);
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
    TListNode *p = (TListNode *)TListBase::Get(pos);
    if (p)
        return *p;
    else
        return EmptyList;
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
    const TListNode *p = &ln;
    return TListBase::Find(p);
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
        return *(TListNode *)FCurrPos;
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
void TList::AddFirst(const TListNode &newln)
{
    TListBase::AddFirst(Clone(&newln));
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
void TList::AddLast(const TListNode &newln)
{
    TListBase::AddLast(Clone(&newln));
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
void TList::AddAt(int n, const TListNode &newln)
{
    TListBase::AddAt(n, Clone(&newln));
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
int TList::Replace(int pos, const TListNode &newln)
{
    return TListBase::Replace(pos, &newln);
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
