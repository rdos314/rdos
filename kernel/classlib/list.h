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
# List base class
#
########################################################################*/

#ifndef _LIST_H
#define _LIST_H

#include "shareobj.h"

class TListNode
{
friend class TList;
public:
	TListNode();
	TListNode(const void *x, int size);
	TListNode(const TListNode &source);
	virtual ~TListNode();

	int IsValid() const;

	const TListNode &operator=(const TListNode &src);
	int operator==(const TListNode &dest) const;
	int operator!=(const TListNode &dest) const;
	int operator>(const TListNode &dest) const;
	int operator>=(const TListNode &dest) const;
	int operator<(const TListNode &dest) const;
	int operator<=(const TListNode &dest) const;

	int GetSize() const;
	const void *GetData() const;
	void SetData(const void *x, int size);

protected:
	int Compare(const TListNode &n2) const;

	int FValid;
	TShareObject *FData;
    TListNode *FNext;
};

class TList
{
public:
	TList();
	TList(const TList &source);
	~TList();

	int GotoFirst();
	int GotoNext();
	int GotoPrev();
	int GotoLast();
	int Goto(int pos);
	int Find(const TListNode &ln);

	TListNode &Get();

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

	void Clear();
	int IsEmpty();
	int GetSize();
	int GetPosition();

	void AddFirst(TListNode &newln);
	void AddLast(TListNode &newln);
	void AddAt(int n, TListNode &newln);

	int RemoveFirst();
	int RemoveLast();
	int RemoveCurrent();
	int Remove(int n);

    int Replace(int n, TListNode &newln);

    void Concat(const TList &src1, const TList &src2); 
    void Intersect(const TList &src1, const TList &src2); 
    void Union(const TList &src1, const TList &src2); 
    void Difference(const TList &src1, const TList &src2); 

    void Reverse();
    void RemoveDuplicates();

protected:
    void Init();
    void Invalidate(TListNode *ln);
	void Load(const TList &src);
	void AddFirst(TListNode *newln);
	void AddLast(TListNode *newln);
	void AddAt(int n, TListNode *newln);
	TListNode *Get(int n);

	int Compare(const TList &l) const;

    TListNode *FList;
    TListNode *FCurrPos;
    TListNode *FPrevPos;
};

TList operator+(const TList& list1, const TList& list2);
TList operator&(const TList& list1, const TList& list2);
TList operator|(const TList& list1, const TList& list2);
TList operator^(const TList& list1, const TList& list2);

#endif
