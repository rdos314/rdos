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
# strlist.h
# Strlist base class
#
########################################################################*/

#ifndef _STRLIST_H
#define _STRLIST_H

#include "list.h"
#include "str.h"

class TStringListNode : public TListNode
{
public:
	TStringListNode();
	TStringListNode(const TString &str);
	TStringListNode(const TStringListNode &source);
	virtual ~TStringListNode();

	TString &Get() const;
	void Set(TString &str);

protected:
	TString *FStr;
};

class TStringList : public TList
{
public:
	TStringList();
	~TStringList();

	TString &Get();
	int operator==(const TStringList &dest) const;
	int operator!=(const TStringList &dest) const;
	int operator>(const TStringList &dest) const;
	int operator>=(const TStringList &dest) const;
	int operator<(const TStringList &dest) const;
	int operator<=(const TStringList &dest) const;
	TStringList &operator=(const TStringList &l);
	TStringList &operator+=(const TStringList &l);
	TStringList &operator&=(const TStringList &l);
	TStringList &operator|=(const TStringList &l);
	TStringList &operator^=(const TStringList &l);
	TString &operator[] (int pos);

	void AddFirst(TString &str);
	void AddLast(TString &str);
	void AddAt(int n, TString &str);

    int Replace(int n, TString &str);

protected:
	virtual TListNode *Clone(const TListNode *ln) const;

};

TStringList operator+(const TStringList& list1, const TStringList& list2);
TStringList operator&(const TStringList& list1, const TStringList& list2);
TStringList operator|(const TStringList& list1, const TStringList& list2);
TStringList operator^(const TStringList& list1, const TStringList& list2);

#endif
