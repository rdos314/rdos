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

#include "strlist.h"

#define FALSE 0
#define TRUE !FALSE

TString EmptyStr;

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
	if (FData)
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
	TStringListNode *p = (TStringListNode *)TList::Get(pos);

	if (p->IsValid())
		return p->Get();
	else
		return EmptyStr;
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
#   Name       : TStringList::AddFirst
#
#   Purpose....: Add entry as first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringList::AddFirst(TString &str)
{
	TList::AddFirst(TStringListNode(str));
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
void TStringList::AddLast(TString &str)
{
	TList::AddLast(TStringListNode(str));
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
void TStringList::AddAt(int n, TString &str)
{
	TList::AddAt(n, TStringListNode(str));
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
int TStringList::Replace(int pos, TString &str)
{
	return TList::Replace(pos, TStringListNode(str));
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
