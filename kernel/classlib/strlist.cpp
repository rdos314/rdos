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

#if defined __GNUC__ || defined MSVC
#include <string.h>
#else
#include <mem.h>
#endif

#include "strlist.h"

#define FALSE 0
#define TRUE !FALSE

static TString EmptyStr;

/*##########################################################################
#
#   Name       : TStringListNode::TStringListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringListNode::TStringListNode()
{
    FStr = 0;
}

/*##########################################################################
#
#   Name       : TStringListNode::TStringListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringListNode::TStringListNode(const TString &str)
{
 	FStr = new TString(str);
	FData = FStr;
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TStringListNode::TStringListNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringListNode::TStringListNode(const TStringListNode &src)
{
	FStr = new TString(*src.FStr);
	FData = FStr;
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TStringListNode::~TStringListNode
#
#   Purpose....: Destructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringListNode::~TStringListNode()
{
}

/*##########################################################################
#
#   Name       : TStringListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::Compare(const TStringListNode &n2) const
{
	if (FStr && n2.FStr)
		return FStr->Compare(*n2.FStr);
	else
	{
		if (FStr || n2.FStr)
		{
			if (FStr)
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
#   Name       : TStringListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::Compare(const TListBaseNode &n2) const
{
    TStringListNode *p = (TStringListNode *)&n2;
    return Compare(*p);    
}

/*##########################################################################
#
#   Name       : TStringListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringListNode::Load(const TStringListNode &src)
{
	if (FStr)
		*FStr = *src.FStr;
	else
	{
		if (src.FData)
			FStr = new TString(*src.FStr);
	}
	FData = FStr;
	FValid = src.FValid;
}

/*##########################################################################
#
#   Name       : TStringListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringListNode::Load(const TListBaseNode &src)
{
	TStringListNode *p = (TStringListNode *)&src;
	Load(*p);
}

/*##########################################################################
#
#   Name       : TStringListNode::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TStringListNode &TStringListNode::operator=(const TStringListNode &src)
{
	Load(src);
	return *this;
}

/*##########################################################################
#
#   Name       : TStringListNode::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::operator==(const TStringListNode &ln) const
{
	if (Compare(ln) == 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringListNode::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::operator!=(const TStringListNode &ln) const
{
	if (Compare(ln) == 0)
		return FALSE;
	else
		return TRUE;
}

/*##########################################################################
#
#   Name       : TStringListNode::operator>
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::operator>(const TStringListNode &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringListNode::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::operator<(const TStringListNode &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringListNode::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::operator>=(const TStringListNode &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringListNode::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringListNode::operator<=(const TStringListNode &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringListNode::Get
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TStringListNode::Get() const
{
	return *FStr;
}

/*##########################################################################
#
#   Name       : TStringListNode::Set
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringListNode::Set(TString &str)
{
	if (FStr)
		*FStr = str;
	else
	{
		FStr = new TString(str);
		FData = FStr;
	} 
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TStringList::TStringList
#
#   Purpose....: Constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList::TStringList()
{
}

/*##########################################################################
#
#   Name       : TStringList::TStringList
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList::TStringList(const TStringList &source)
  : TListBase(source)
{
}

/*##########################################################################
#
#   Name       : TStringList::~TStringList
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList::~TStringList()
{
}

/*##########################################################################
#
#   Name       : TStringList::operator==
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::operator==(const TStringList &l) const
{
    if (Compare(l) == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TStringList::operator!=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::operator!= (const TStringList &l) const
{
    if (Compare(l) != 0)
        return TRUE;
    else
        return FALSE;
}    

/*##########################################################################
#
#   Name       : TStringList::operator>
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::operator>(const TStringList &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringList::operator<
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::operator<(const TStringList &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringList::operator>=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::operator>=(const TStringList &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringList::operator<=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::operator<=(const TStringList &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringList::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList &TStringList::operator=(const TStringList &src)
{
	Load(src);
    return *this;
}

/*##########################################################################
#
#   Name       : TStringList::operator+=
#
#   Purpose....: Concat operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList &TStringList::operator+=(const TStringList &l)
{
	TStringList list;
	list.Concat(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TStringList::operator&=
#
#   Purpose....: Intersec operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList &TStringList::operator&=(const TStringList &l)
{
	TStringList list;
	list.Intersect(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TStringList::operator|=
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList &TStringList::operator|=(const TStringList &l)
{
	TStringList list;
	list.Union(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TStringList::operator^=
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList &TStringList::operator^=(const TStringList &l)
{
	TStringList list;
	list.Difference(*this, l);
	*this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TStringList::operator[]
#
#   Purpose....: Vector operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TStringList::operator[](int pos)
{
	TStringListNode *p = (TStringListNode *)TListBase::Get(pos);

	if (p->IsValid())
		return p->Get();
	else
		return EmptyStr;
}

/*##########################################################################
#
#   Name       : TStringList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringListNode *TStringList::Clone(const TStringListNode *ln) const
{
	return new TStringListNode(*ln);
}

/*##########################################################################
#
#   Name       : TStringList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode *TStringList::Clone(const TListBaseNode *ln) const
{
    TStringListNode *p = (TStringListNode *)ln;
	return new TStringListNode(*p);
}

/*##########################################################################
#
#   Name       : TStringList::Get
#
#   Purpose....: Get current data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TStringList::Get()
{
	if (FCurrPos)
		return ((TStringListNode *)FCurrPos)->Get();
	else
		return EmptyStr;
}

/*##########################################################################
#
#   Name       : TStringList::Find
#
#   Purpose....: Find specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::Find(const TString &str)
{
	TStringListNode n = TStringListNode(str);
	return TListBase::Find(&n);
}

/*##########################################################################
#
#   Name       : TStringList::AddFirst
#
#   Purpose....: Add entry as first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringList::AddFirst(const TString &str)
{
	TStringListNode *p = new TStringListNode(str);
	TListBase::AddFirst(p);
}

/*##########################################################################
#
#   Name       : TStringList::AddLast
#
#   Purpose....: Add entry as last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringList::AddLast(const TString &str)
{
	TStringListNode *p = new TStringListNode(str);
	TListBase::AddLast(p);
}

/*##########################################################################
#
#   Name       : TStringList::AddAt
#
#   Purpose....: Add entry at specified position, if possible.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringList::AddAt(int n, const TString &str)
{
	TStringListNode *p = new TStringListNode(str);
	TListBase::AddAt(n, p);
}

/*##########################################################################
#
#   Name       : TStringList::Replace
#
#   Purpose....: Replace specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringList::Replace(int pos, const TString &str)
{
	TStringListNode n = TStringListNode(str);
	return TListBase::Replace(pos, &n);
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
TStringList operator+(const TStringList &list1, const TStringList& list2)
{
	TStringList list;
    list.Concat(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator&
#
#   Purpose....: Intersection operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList operator&(const TStringList &list1, const TStringList& list2)
{
	TStringList list;
    list.Intersect(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator|
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList operator|(const TStringList &list1, const TStringList& list2)
{
	TStringList list;
    list.Union(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator^
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringList operator^(const TStringList &list1, const TStringList& list2)
{
	TStringList list;
    list.Difference(list1, list2);
    return list;
}
