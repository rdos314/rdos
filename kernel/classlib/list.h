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
# list.h
# List class
#
########################################################################*/

#ifndef _LIST_H
#define _LIST_H

#include "listbase.h"

class TListNode : public TListBaseNode
{
public:
	TListNode();
	TListNode(const void *x, int size);
	TListNode(const TListNode &source);
	virtual ~TListNode();

	const TListNode &operator=(const TListNode &src);
	int operator==(const TListNode &dest) const;
	int operator!=(const TListNode &dest) const;
	int operator>(const TListNode &dest) const;
	int operator>=(const TListNode &dest) const;
	int operator<(const TListNode &dest) const;
	int operator<=(const TListNode &dest) const;

protected:
	virtual int Compare(const TListNode &n2) const;
	virtual int Compare(const TListBaseNode &n2) const;
	virtual void Load(const TListNode &src);
	virtual void Load(const TListBaseNode &src);
};

class TList : public TListBase
{
public:
	TList();
	TList(const TList &source);
	~TList();

	int operator==(const TList &dest) const;
	int operator!=(const TList &dest) const;
	int operator>(const TList &dest) const;
	int operator>=(const TList &dest) const;
	int operator<(const TList &dest) const;
	int operator<=(const TList &dest) const;
	TList &operator=(const TList &l);
	TList &operator+=(const TList &l);
	TList &operator&=(const TList &l);
	TList &operator|=(const TList &l);
	TList &operator^=(const TList &l);
	TListNode &operator[] (int pos);

	TListNode &Get();

	int Find(const TListNode &ln);
	void AddFirst(const TListNode &newln);
	void AddLast(const TListNode &newln);
	void AddAt(int n, const TListNode &newln);
    int Replace(int n, const TListNode &newln);

protected:
	virtual TListNode *Clone(const TListNode *ln) const;
	virtual TListBaseNode *Clone(const TListBaseNode *ln) const;
};

TList operator+(const TList& list1, const TList& list2);
TList operator&(const TList& list1, const TList& list2);
TList operator|(const TList& list1, const TList& list2);
TList operator^(const TList& list1, const TList& list2);

#endif
