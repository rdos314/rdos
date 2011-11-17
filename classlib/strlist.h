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

#include "listbase.h"
#include "str.h"

class TStringListNode : public TListBaseNode
{
public:
	TStringListNode();
	TStringListNode(const TString &str);
	TStringListNode(const TStringListNode &source);
	virtual ~TStringListNode();

	const TStringListNode &operator=(const TStringListNode &src);
	int operator==(const TStringListNode &dest) const;
	int operator!=(const TStringListNode &dest) const;
	int operator>(const TStringListNode &dest) const;
	int operator>=(const TStringListNode &dest) const;
	int operator<(const TStringListNode &dest) const;
	int operator<=(const TStringListNode &dest) const;

	TString &Get() const;
	void Set(TString &str);

protected:
	virtual int Compare(const TStringListNode &n2) const;
	virtual int Compare(const TListBaseNode &n2) const;
	virtual void Load(const TStringListNode &src);
	virtual void Load(const TListBaseNode &src);
	
	TString *FStr;
};

class TStringList : public TListBase
{
public:
	TStringList();
	TStringList(const TStringList &source);
	~TStringList();

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

	TString &Get();
	
	int Find(const TString &str);
	void AddFirst(const TString &str);
	void AddLast(const TString &str);
	void AddAt(int n, const TString &str);
    int Replace(int n, const TString &str);

protected:
	virtual TStringListNode *Clone(const TStringListNode *ln) const;
	virtual TListBaseNode *Clone(const TListBaseNode *ln) const;

};

TStringList operator+(const TStringList& list1, const TStringList& list2);
TStringList operator&(const TStringList& list1, const TStringList& list2);
TStringList operator|(const TStringList& list1, const TStringList& list2);
TStringList operator^(const TStringList& list1, const TStringList& list2);

#endif
