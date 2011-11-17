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
# Strarr.cpp
# String array class
#
########################################################################*/

#if defined __GNUC__ || defined MSVC
#include <string.h>
#else
#include <mem.h>
#endif

#include "strarr.h"

#define FALSE 0
#define TRUE !FALSE

static TString EmptyStr;

/*##########################################################################
#
#   Name       : TStringArrayNode::TStringArrayNode
#
#   Purpose....: Constructor for array-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArrayNode::TStringArrayNode()
{
    FStr = 0;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::TStringArrayNode
#
#   Purpose....: Constructor for array-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArrayNode::TStringArrayNode(const TString &str)
{
 	FStr = new TString(str);
	FData = FStr;
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::TStringArrayNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArrayNode::TStringArrayNode(const TStringArrayNode &src)
{
	FStr = new TString(*src.FStr);
	FData = FStr;
	FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::~TStringArrayNode
#
#   Purpose....: Destructor for array-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArrayNode::~TStringArrayNode()
{
}

/*##########################################################################
#
#   Name       : TStringArrayNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::Compare(const TStringArrayNode &n2) const
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
#   Name       : TStringArrayNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::Compare(const TArrayBaseNode &n2) const
{
    TStringArrayNode *p = (TStringArrayNode *)&n2;
    return Compare(*p);    
}

/*##########################################################################
#
#   Name       : TStringArrayNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringArrayNode::Load(const TStringArrayNode &src)
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
#   Name       : TStringArrayNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringArrayNode::Load(const TArrayBaseNode &src)
{
	TStringArrayNode *p = (TStringArrayNode *)&src;
	Load(*p);
}

/*##########################################################################
#
#   Name       : TStringArrayNode::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TStringArrayNode &TStringArrayNode::operator=(const TStringArrayNode &src)
{
	Load(src);
	return *this;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::operator==(const TStringArrayNode &ln) const
{
	if (Compare(ln) == 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::operator!=(const TStringArrayNode &ln) const
{
	if (Compare(ln) == 0)
		return FALSE;
	else
		return TRUE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::operator>
#
#   Purpose....: Compare array nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::operator>(const TStringArrayNode &dest) const
{
	if (Compare(dest) > 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::operator<(const TStringArrayNode &dest) const
{
	if (Compare(dest) < 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::operator>=(const TStringArrayNode &dest) const
{
	if (Compare(dest) >= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStringArrayNode::operator<=(const TStringArrayNode &dest) const
{
	if (Compare(dest) <= 0)
		return TRUE;
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::Get
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TStringArrayNode::Get() const
{
	return *FStr;
}

/*##########################################################################
#
#   Name       : TStringArrayNode::Set
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringArrayNode::Set(TString &str)
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
#   Name       : TStringArray::TStringArray
#
#   Purpose....: Constructor for array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArray::TStringArray()
{
}

/*##########################################################################
#
#   Name       : TStringArray::TStringArray
#
#   Purpose....: Copy constructor for array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArray::TStringArray(const TStringArray &source)
  : TArrayBase(source)
{
}

/*##########################################################################
#
#   Name       : TStringArray::~TStringArray
#
#   Purpose....: Destructor for array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArray::~TStringArray()
{
}

/*##########################################################################
#
#   Name       : TStringArray::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArray &TStringArray::operator=(const TStringArray &src)
{
	Load(src);
    return *this;
}

/*##########################################################################
#
#   Name       : TStringArray::operator+=
#
#   Purpose....: Concat operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArray &TStringArray::operator+=(const TStringArray &l)
{
	TStringArray arr;
	arr.Concat(*this, l);
	*this = arr;
    return *this;
}

/*##########################################################################
#
#   Name       : TStringArray::operator[]
#
#   Purpose....: Vector operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TStringArray::operator[](int pos)
{
	TStringArrayNode *p = (TStringArrayNode *)TArrayBase::Get(pos);

	if (p && p->IsValid())
		return p->Get();
	else
		return EmptyStr;
}

/*##########################################################################
#
#   Name       : TStringArray::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStringArrayNode *TStringArray::Clone(const TStringArrayNode *ln) const
{
	return new TStringArrayNode(*ln);
}

/*##########################################################################
#
#   Name       : TStringArray::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TArrayBaseNode *TStringArray::Clone(const TArrayBaseNode *ln) const
{
    TStringArrayNode *p = (TStringArrayNode *)ln;
	return new TStringArrayNode(*p);
}

/*##########################################################################
#
#   Name       : TStringArray::Get
#
#   Purpose....: Get data at position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TStringArray::Get(int pos)
{
	TStringArrayNode *p = (TStringArrayNode *)TArrayBase::Get(pos);

	if (p && p->IsValid())
		return p->Get();
	else
		return EmptyStr;
}

/*##########################################################################
#
#   Name       : TStringArray::Add
#
#   Purpose....: Add entry last
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringArray::Add(const TString &str)
{
	TStringArrayNode *p = new TStringArrayNode(str);
	TArrayBase::Add(p);
}

/*##########################################################################
#
#   Name       : TStringArray::Add
#
#   Purpose....: Add entry at specified position, if possible.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringArray::Add(int pos, const TString &str)
{
	TStringArrayNode *p = new TStringArrayNode(str);
	TArrayBase::Add(pos, p);
}

/*##########################################################################
#
#   Name       : TStringArray::Replace
#
#   Purpose....: Replace specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStringArray::Replace(int pos, const TString &str)
{
	TStringArrayNode n = TStringArrayNode(str);
	TArrayBase::Replace(pos, &n);
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
TStringArray operator+(const TStringArray &arr1, const TStringArray& arr2)
{
	TStringArray arr;
    arr.Concat(arr1, arr2);
    return arr;
}
